import threading

from django.db import close_old_connections
from django.utils import timezone

from apps.common.exceptions import APIError
from apps.translations.client import LibreTranslateClient
from apps.translations.extractors import extract_pages
from apps.translations.models import Translation, TranslationPage

MAX_CHUNK_CHARS = 4500


def document_version(document):
    """Fingerprint del contenido del documento usado para validar traducciones.

    Combina el tamaño del archivo y la fecha de modificación; si el archivo
    cambia, la versión cambia y las traducciones existentes se invalidan.
    """
    updated_ms = int(document.updated_at.timestamp() * 1000) if document.updated_at else 0
    return f"{document.file_size}:{updated_ms}"


class TranslationService:
    """Lógica de negocio del flujo de traducción."""

    def __init__(self, client=None):
        self.client = client or LibreTranslateClient()

    def start(self, document, target_language, source_language="auto"):
        """Crea la traducción y extrae las páginas del documento.

        Devuelve ``(translation, started)`` donde ``started`` indica si el
        proceso debe ejecutarse. Una traducción activa existente se reutiliza
        salvo que el documento haya cambiado (source_version desactualizada),
        en cuyo caso se invalida antes de permitir una nueva traducción.
        """
        existing = Translation.objects.filter(
            document=document,
            target_language=target_language,
        ).first()

        if existing:
            if existing.status in {Translation.Status.COMPLETED, Translation.Status.PARTIAL}:
                if existing.source_version and existing.source_version != document_version(document):
                    self._discard(existing)
                else:
                    return existing, False
            if existing.status in {Translation.Status.PENDING, Translation.Status.PROCESSING}:
                return existing, False
            self._discard(existing)

        pages_text = extract_pages(document)
        translation = Translation.objects.create(
            document=document,
            source_language=source_language,
            target_language=target_language,
            source_version=document_version(document),
            status=Translation.Status.PENDING,
            total_pages=len(pages_text),
        )
        TranslationPage.objects.bulk_create(
            [
                TranslationPage(
                    translation=translation,
                    page_number=index,
                    original_content=text,
                )
                for index, text in enumerate(pages_text, start=1)
            ]
        )
        translation.status = Translation.Status.PROCESSING
        translation.save(update_fields=["status", "updated_at"])
        return translation, True

    def start_async(self, translation_id):
        """Procesa la traducción en un hilo en segundo plano."""
        thread = threading.Thread(
            target=self._run_background,
            args=(translation_id,),
            daemon=True,
        )
        thread.start()

    def process(self, translation_id):
        """Traduce cada página de forma independiente y tolerante a fallos."""
        translation = Translation.objects.get(pk=translation_id)
        processed = 0
        failed = 0

        for page in translation.pages.all():
            self._translate_page(translation, page)
            if page.status == TranslationPage.Status.COMPLETED:
                processed += 1
            else:
                failed += 1
            translation.processed_pages = processed
            translation.failed_pages = failed
            translation.save(update_fields=["processed_pages", "failed_pages", "updated_at"])

        if failed == 0:
            translation.status = Translation.Status.COMPLETED
        elif processed == 0:
            translation.status = Translation.Status.FAILED
        else:
            translation.status = Translation.Status.PARTIAL
        translation.save(update_fields=["status", "updated_at"])
        return translation

    def _translate_page(self, translation, page):
        try:
            translated = self._translate_content(
                page.original_content,
                translation.source_language,
                translation.target_language,
            )
            page.translated_content = translated
            page.status = TranslationPage.Status.COMPLETED
            page.error_message = ""
        except Exception as exc:  # noqa: BLE001 - el fallo es por página
            page.status = TranslationPage.Status.FAILED
            page.error_message = str(exc)[:500]
        page.save()

    def _translate_content(self, content, source_language, target_language):
        if not content.strip():
            return ""
        chunks = split_into_chunks(content, MAX_CHUNK_CHARS)
        parts = [
            self.client.translate(chunk, target_language, source_language)
            for chunk in chunks
        ]
        return "\n\n".join(parts)

    def _discard(self, translation):
        translation.pages.all().delete()
        translation.deleted_at = timezone.now()
        translation.save(update_fields=["deleted_at", "updated_at"])

    def delete(self, translation):
        """Elimina lógicamente una traducción y sus páginas."""
        self._discard(translation)
        return translation

    def _run_background(self, translation_id):
        close_old_connections()
        try:
            self.process(translation_id)
        finally:
            close_old_connections()


def split_into_chunks(text, max_chars=MAX_CHUNK_CHARS):
    """Divide un texto en fragmentos de tamaño limitado por párrafos."""
    paragraphs = [paragraph for paragraph in text.split("\n\n") if paragraph.strip()]
    chunks = []
    current = []
    current_len = 0

    for paragraph in paragraphs:
        parts = _hard_split(paragraph, max_chars)
        for part in parts:
            if current_len + len(part) + 2 > max_chars and current:
                chunks.append("\n\n".join(current))
                current = []
                current_len = 0
            current.append(part)
            current_len += len(part) + 2

    if current:
        chunks.append("\n\n".join(current))
    return chunks


def _hard_split(text, max_chars):
    """Divide un párrafo muy largo en fragmentos por espacios."""
    if len(text) <= max_chars:
        return [text]
    words = text.split(" ")
    parts = []
    current = []
    current_len = 0
    for word in words:
        while len(word) > max_chars:
            if current:
                parts.append(" ".join(current))
                current = []
                current_len = 0
            parts.append(word[:max_chars])
            word = word[max_chars:]
        if current_len + len(word) + 1 > max_chars and current:
            parts.append(" ".join(current))
            current = [word]
            current_len = len(word)
        else:
            current.append(word)
            current_len += len(word) + 1
    if current:
        parts.append(" ".join(current))
    return parts
