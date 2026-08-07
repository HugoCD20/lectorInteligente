from django.core.cache import cache

from apps.translations.extractors import extract_pages

_CACHE_TTL_SECONDS = 300
_MAX_PAGE_SIZE = 20
_PAGES_CACHE_PREFIX = "reader:pages"


class ReadingService:
    """Consulta de páginas del documento original con su traducción.

    Las páginas originales se extraen del archivo bajo demanda y se cachean
    mediante el cache framework de Django (Redis en entornos con múltiples
    procesos); la extracción se invalida si el archivo cambia.
    """

    def read(self, document, page=None, page_size=None, target_language=None):
        """Devuelve una ventana de páginas del documento.

        Si [target_language] es un idioma con traducción, cada página incluye
        además el contenido traducido alineado por número de página.
        """
        pages = self._get_pages(document)
        total_pages = len(pages)
        if total_pages == 0:
            return self._build_result(document, 1, [], target_language, total_pages)

        page_number = max(1, min(page or 1, total_pages))
        page_size = max(1, min(page_size or 1, _MAX_PAGE_SIZE))
        end = min(page_number + page_size - 1, total_pages)

        window = [
            {
                "page_number": number,
                "original_content": pages[number - 1],
            }
            for number in range(page_number, end + 1)
        ]
        return self._build_result(document, page_number, window, target_language, total_pages)

    def _build_result(self, document, page_number, window, target_language, total_pages):
        translation_data = None
        if target_language:
            from apps.translations.models import Translation, TranslationPage

            translation = Translation.objects.filter(
                document=document,
                target_language=target_language,
            ).first()
            if translation is not None:
                translation_data = self._summary(translation)
                translated = {
                    page.page_number: page
                    for page in translation.pages.filter(
                        status=TranslationPage.Status.COMPLETED
                    )
                }
                for item in window:
                    page = translated.get(item["page_number"])
                    item["translated_content"] = (
                        page.translated_content if page is not None else None
                    )
        return {
            "total_pages": total_pages,
            "page": page_number,
            "page_size": len(window),
            "target_language": target_language,
            "translation": translation_data,
            "pages": window,
        }

    def _summary(self, translation):
        from apps.translations.serializers import TranslationSummarySerializer

        return TranslationSummarySerializer(translation).data

    def _get_pages(self, document):
        cache_key = (
            f"{_PAGES_CACHE_PREFIX}:{document.id}:"
            f"{document.file_size}:{document.updated_at.timestamp()}"
        )
        pages = cache.get(cache_key)
        if pages is None:
            pages = extract_pages(document)
            cache.set(cache_key, pages, timeout=_CACHE_TTL_SECONDS)
        return pages
