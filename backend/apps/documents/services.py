from django.utils import timezone
from pathlib import Path

from apps.documents.models import Document
from apps.documents.validators import normalize_original_name


class DocumentService:
    """Lógica de negocio de la gestión de documentos."""

    def upload(self, user, file):
        """Almacena el archivo y registra el documento del usuario."""
        original_name = normalize_original_name(file.name)
        extension = Path(original_name).suffix.lower().lstrip(".")
        return Document.objects.create(
            user=user,
            file=file,
            original_name=original_name,
            extension=extension,
            mime_type=file.content_type or "application/octet-stream",
            file_size=file.size,
            last_opened_at=timezone.now(),
        )

    def open(self, document):
        """Registra la apertura del documento en el historial reciente."""
        document.last_opened_at = timezone.now()
        document.save(update_fields=["last_opened_at", "updated_at"])
        return document

    def soft_delete(self, document):
        """Elimina lógicamente el documento y sus traducciones.

        Las páginas se borran y las traducciones se marcan como eliminadas
        mediante operaciones en masa (una consulta por cada tipo).
        """
        from apps.translations.models import Translation, TranslationPage

        document.deleted_at = timezone.now()
        document.save(update_fields=["deleted_at", "updated_at"])

        translations = Translation.objects.filter(document=document)
        TranslationPage.objects.filter(translation__in=translations).delete()
        translations.update(deleted_at=timezone.now(), updated_at=timezone.now())
        return document
