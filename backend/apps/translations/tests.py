import io
import zipfile
from unittest.mock import Mock, patch

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase
from django.urls import reverse
from pypdf import PdfWriter
from pypdf.generic import DecodedStreamObject, DictionaryObject, NameObject
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework.throttling import ScopedRateThrottle

from apps.common.exceptions import APIError
from apps.documents.models import Document
from apps.documents.services import DocumentService
from apps.translations.client import LibreTranslateClient
from apps.translations.extractors import extract_epub_pages, extract_pdf_pages
from apps.translations.models import Translation, TranslationPage
from apps.translations.services import TranslationService, document_version, split_into_chunks
User = get_user_model()


def run_sync(translation_id):
    TranslationService(client=FakeClient()).process(translation_id)


SUPPORTED_LANGUAGES = [
    {"code": "en", "name": "English"},
    {"code": "es", "name": "Spanish"},
    {"code": "fr", "name": "French"},
]


class FakeClient:
    """Cliente simulado que falla cuando el texto contiene 'FAIL'."""

    def translate(self, text, target_language, source_language="auto"):
        if "FAIL" in text:
            raise APIError("Error simulado del motor.")
        return f"[{target_language}] {text}"

    def languages(self):
        return SUPPORTED_LANGUAGES


def make_pdf(*page_texts):
    writer = PdfWriter()
    for text in page_texts:
        page = writer.add_blank_page(width=612, height=792)
        content = DecodedStreamObject()
        content.set_data(f"BT /F1 12 Tf 72 720 Td ({text}) Tj ET".encode())
        page[NameObject("/Contents")] = writer._add_object(content)
        page[NameObject("/Resources")] = DictionaryObject(
            {
                NameObject("/Font"): DictionaryObject(
                    {
                        NameObject("/F1"): writer._add_object(
                            DictionaryObject(
                                {
                                    NameObject("/Type"): NameObject("/Font"),
                                    NameObject("/Subtype"): NameObject("/Type1"),
                                    NameObject("/BaseFont"): NameObject("/Helvetica"),
                                }
                            )
                        )
                    }
                )
            }
        )
    buffer = io.BytesIO()
    writer.write(buffer)
    buffer.seek(0)
    return buffer.read()


def make_epub(*chapters):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        archive.writestr(
            "META-INF/container.xml",
            '<?xml version="1.0"?>'
            '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
            '<rootfiles><rootfile full-path="OEBPS/content.opf" '
            'media-type="application/oebps-package+xml"/></rootfiles></container>',
        )
        manifest = "".join(
            f'<item id="c{i}" href="chap{i}.xhtml" media-type="application/xhtml+xml"/>'
            for i in range(1, len(chapters) + 1)
        )
        spine = "".join(f'<itemref idref="c{i}"/>' for i in range(1, len(chapters) + 1))
        archive.writestr(
            "OEBPS/content.opf",
            '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
            f"<manifest>{manifest}</manifest><spine>{spine}</spine></package>",
        )
        for index, chapter in enumerate(chapters, start=1):
            archive.writestr(
                f"OEBPS/chap{index}.xhtml",
                '<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml">'
                f"<body><p>{chapter}</p></body></html>",
            )
    buffer.seek(0)
    return buffer.read()


def create_document(user, file_bytes, file_name="libro.pdf"):
    return DocumentService().upload(
        user,
        SimpleUploadedFile(file_name, file_bytes, content_type="application/pdf"),
    )


class ExtractorTests(APITestCase):
    def test_extract_pdf_pages(self):
        pages = extract_pdf_pages(io.BytesIO(make_pdf("Hola uno", "Hola dos")))
        self.assertEqual(pages, ["Hola uno", "Hola dos"])

    def test_extract_epub_pages(self):
        pages = extract_epub_pages(io.BytesIO(make_epub("Cap uno", "Cap dos")))
        self.assertEqual(pages, ["Cap uno", "Cap dos"])

    def test_split_into_chunks_respects_limit(self):
        text = "\n\n".join(f"párrafo {i} " + "x" * 100 for i in range(20))
        chunks = split_into_chunks(text, max_chars=400)
        self.assertGreater(len(chunks), 1)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 400)

    def test_extract_unsupported_format(self):
        document = create_document(
            self._user(),
            make_epub("a"),
            file_name="libro.epub",
        )
        document.extension = "txt"
        with self.assertRaises(APIError):
            from apps.translations.extractors import extract_pages

            extract_pages(document)

    def test_extract_pages_propagates_api_error(self):
        document = create_document(
            self._user(),
            make_epub("a"),
            file_name="libro.epub",
        )
        from apps.translations.extractors import extract_pages

        with patch(
            "apps.translations.extractors.extract_epub_pages",
            side_effect=APIError("estructura inválida"),
        ):
            with self.assertRaises(APIError):
                extract_pages(document)

    def test_extract_pages_wraps_unexpected_errors(self):
        document = create_document(
            self._user(),
            make_epub("a"),
            file_name="libro.epub",
        )
        from apps.translations.extractors import extract_pages

        with patch(
            "apps.translations.extractors.extract_epub_pages",
            side_effect=ValueError("inesperado"),
        ):
            with self.assertRaises(APIError):
                extract_pages(document)

    @patch("apps.translations.extractors.MAX_EXTRACTED_PAGES", 1)
    def test_extract_epub_page_limit_rejected(self, *_):
        with self.assertRaises(APIError):
            extract_epub_pages(io.BytesIO(make_epub("Cap uno", "Cap dos")))

    def test_epub_without_valid_structure_rejected(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            archive.writestr(
                "META-INF/container.xml",
                '<?xml version="1.0"?>'
                '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"/>',
            )
        buffer.seek(0)
        with self.assertRaises(APIError):
            extract_epub_pages(buffer)

    def _make_epub_with(self, manifest, spine, files=None):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w") as archive:
            archive.writestr(
                "META-INF/container.xml",
                '<?xml version="1.0"?>'
                '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
                '<rootfiles><rootfile full-path="OEBPS/content.opf" '
                'media-type="application/oebps-package+xml"/></rootfiles></container>',
            )
            archive.writestr(
                "OEBPS/content.opf",
                '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
                f"<manifest>{manifest}</manifest><spine>{spine}</spine></package>",
            )
            for name, content in (files or {}).items():
                archive.writestr(name, content)
        buffer.seek(0)
        return buffer

    def test_epub_skips_missing_content_file(self):
        epub = self._make_epub_with(
            manifest='<item id="c1" href="chap1.xhtml" media-type="application/xhtml+xml"/>',
            spine='<itemref idref="c1"/>',
        )
        self.assertEqual(extract_epub_pages(epub), [])

    def test_epub_skips_spine_item_not_in_manifest(self):
        epub = self._make_epub_with(
            manifest='<item id="c1" href="chap1.xhtml" media-type="application/xhtml+xml"/>',
            spine='<itemref idref="fantasma"/>',
            files={"OEBPS/chap1.xhtml": "<html><body><p>Contenido</p></body></html>"},
        )
        self.assertEqual(extract_epub_pages(epub), [])

    def _user(self):
        return User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )


class TranslationServiceTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.service = TranslationService(client=FakeClient())

    def test_start_creates_translation_and_pages(self):
        document = create_document(self.user, make_pdf("Uno", "Dos"))
        translation, started = self.service.start(document, "en")
        self.assertTrue(started)
        self.assertEqual(translation.status, Translation.Status.PROCESSING)
        self.assertEqual(translation.total_pages, 2)
        self.assertEqual(translation.pages.count(), 2)

    def test_process_completes_all_pages(self):
        document = create_document(self.user, make_pdf("Uno", "Dos"))
        translation, _ = self.service.start(document, "en")
        result = self.service.process(translation.id)
        self.assertEqual(result.status, Translation.Status.COMPLETED)
        self.assertEqual(result.processed_pages, 2)
        self.assertEqual(result.failed_pages, 0)
        self.assertTrue(
            translation.pages.filter(
                page_number=1, translated_content="[en] Uno"
            ).exists()
        )

    def test_process_continues_when_a_page_fails(self):
        document = create_document(self.user, make_pdf("Uno", "FAIL", "Tres"))
        translation, _ = self.service.start(document, "en")
        result = self.service.process(translation.id)
        self.assertEqual(result.status, Translation.Status.PARTIAL)
        self.assertEqual(result.processed_pages, 2)
        self.assertEqual(result.failed_pages, 1)
        failed_page = translation.pages.get(page_number=2)
        self.assertEqual(failed_page.status, TranslationPage.Status.FAILED)
        self.assertTrue(failed_page.error_message)

    def test_completed_translation_is_reused(self):
        document = create_document(self.user, make_pdf("Uno"))
        translation, started = self.service.start(document, "en")
        self.service.process(translation.id)
        self.assertTrue(translation.source_version)

        again, started_again = self.service.start(document, "en")
        self.assertFalse(started_again)
        self.assertEqual(again.id, translation.id)

    def test_stale_translation_is_invalidated_when_document_changes(self):
        document = create_document(self.user, make_pdf("Uno"))
        translation, _ = self.service.start(document, "en")
        self.service.process(translation.id)

        document.file_size += 1
        document.save(update_fields=["file_size", "updated_at"])

        retry, started = self.service.start(document, "en")
        self.assertTrue(started)
        self.assertNotEqual(retry.id, translation.id)
        translation.refresh_from_db()
        self.assertIsNotNone(translation.deleted_at)
        self.assertEqual(retry.source_version, document_version(document))

    def test_translation_without_version_is_not_invalidated(self):
        document = create_document(self.user, make_pdf("Uno"))
        translation, _ = self.service.start(document, "en")
        self.service.process(translation.id)
        translation.source_version = ""
        translation.save(update_fields=["source_version", "updated_at"])

        again, started = self.service.start(document, "en")
        self.assertFalse(started)
        self.assertEqual(again.id, translation.id)

    def test_processing_translation_is_not_duplicated(self):
        document = create_document(self.user, make_pdf("Uno"))
        translation, started = self.service.start(document, "en")
        self.assertTrue(started)

        again, started_again = self.service.start(document, "en")
        self.assertFalse(started_again)
        self.assertEqual(again.id, translation.id)

    def test_failed_translation_can_be_restarted(self):
        document = create_document(self.user, make_pdf("FAIL"))
        translation, _ = self.service.start(document, "en")
        result = self.service.process(translation.id)
        self.assertEqual(result.status, Translation.Status.FAILED)

        retry, started = self.service.start(document, "en")
        self.assertTrue(started)
        self.assertNotEqual(retry.id, translation.id)
        translation.refresh_from_db()
        self.assertIsNotNone(translation.deleted_at)

    def test_multiple_languages_allowed(self):
        document = create_document(self.user, make_pdf("Uno"))
        en, _ = self.service.start(document, "en")
        es, _ = self.service.start(document, "es")
        self.assertNotEqual(en.id, es.id)


class TranslationApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.other = User.objects.create_user(
            email="other@example.com",
            password="StrongPass123!",
        )
        self.client.force_authenticate(self.user)
        self.document = create_document(self.user, make_pdf("Uno", "Dos"))
        self.foreign_document = create_document(self.other, make_pdf("Ajeno"))

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(LibreTranslateClient, "translate", side_effect=FakeClient().translate)
    @patch.object(TranslationService, "start_async", side_effect=run_sync)
    def test_translate_endpoint_returns_202(self, *mocks):
        response = self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "en"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["target_language"], "en")

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    def test_translate_rejects_unsupported_language(self, *mocks):
        response = self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "xx"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(response.json()["success"])

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    def test_translate_requires_authentication(self, *mocks):
        self.client.force_authenticate(user=None)
        response = self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "en"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_translate_forbidden_for_other_user(self):
        response = self.client.post(
            reverse("document-translate", args=[self.foreign_document.pk]),
            {"target_language": "en"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(LibreTranslateClient, "translate", side_effect=FakeClient().translate)
    @patch.object(TranslationService, "start_async", side_effect=run_sync)
    def test_translations_list(self, *mocks):
        self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "en"},
            format="json",
        )
        response = self.client.get(
            reverse("document-translations", args=[self.document.pk])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()["data"]
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["target_language"], "en")

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(LibreTranslateClient, "translate", side_effect=FakeClient().translate)
    @patch.object(TranslationService, "start_async", side_effect=run_sync)
    def test_translation_detail_includes_pages(self, *mocks):
        self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "en"},
            format="json",
        )
        response = self.client.get(
            reverse("translation-detail", args=[self.document.pk, "en"])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()["data"]
        self.assertEqual(body["target_language"], "en")
        self.assertEqual(len(body["pages"]), 2)
        self.assertEqual(body["pages"][0]["translated_content"], "[en] Uno")

    def test_translation_detail_not_found_for_other_user(self):
        response = self.client.get(
            reverse("translation-detail", args=[self.foreign_document.pk, "en"])
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(LibreTranslateClient, "translate", side_effect=FakeClient().translate)
    @patch.object(TranslationService, "start_async", side_effect=run_sync)
    def test_delete_translation(self, *mocks):
        self.client.post(
            reverse("document-translate", args=[self.document.pk]),
            {"target_language": "en"},
            format="json",
        )
        response = self.client.delete(
            reverse("translation-detail", args=[self.document.pk, "en"])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

        self.assertEqual(
            self.client.get(
                reverse("document-translations", args=[self.document.pk])
            ).json()["data"],
            [],
        )
        detail = self.client.get(
            reverse("translation-detail", args=[self.document.pk, "en"])
        )
        self.assertEqual(detail.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_translation_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.delete(
            reverse("translation-detail", args=[self.document.pk, "en"])
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_delete_translation_not_found_for_other_user(self):
        response = self.client.delete(
            reverse("translation-detail", args=[self.foreign_document.pk, "en"])
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_missing_translation_returns_404(self):
        response = self.client.delete(
            reverse("translation-detail", args=[self.document.pk, "fr"])
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    def test_languages_endpoint(self, *mocks):
        response = self.client.get(reverse("translation-languages"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()["data"]
        self.assertEqual(len(data), 3)
        self.assertIn("es", {item["code"] for item in data})

    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(TranslationService, "start_async")
    def test_translate_reuses_active_translation(self, *mocks):
        url = reverse("document-translate", args=[self.document.pk])
        first = self.client.post(url, {"target_language": "en"}, format="json")
        self.assertEqual(first.status_code, status.HTTP_202_ACCEPTED)

        second = self.client.post(url, {"target_language": "en"}, format="json")
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(second.json()["message"], "Traducción disponible.")

    def test_translation_str_representations(self):
        service = TranslationService(client=FakeClient())
        translation, _ = service.start(self.document, "en")
        self.assertIn(str(self.document.pk), str(translation))
        self.assertIn("en", str(translation))

        page = translation.pages.first()
        self.assertIn(f"página {page.page_number}", str(page))
        self.assertIn(str(translation.pk), str(page))


class TranslationCascadeTests(APITestCase):
    def test_document_delete_soft_deletes_translations(self):
        user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        document = create_document(user, make_pdf("Uno"))
        service = TranslationService(client=FakeClient())
        translation, _ = service.start(document, "en")
        service.process(translation.id)

        DocumentService().soft_delete(document)

        translation.refresh_from_db()
        self.assertIsNotNone(translation.deleted_at)
        self.assertFalse(Translation.objects.filter(pk=translation.pk).exists())
        self.assertEqual(translation.pages.count(), 0)


class ExtractionLimitTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.client.force_authenticate(self.user)

    @patch("apps.translations.extractors.MAX_EPUB_UNCOMPRESSED_BYTES", 100)
    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    def test_epub_exceeding_uncompressed_limit_rejected(self, *mocks):
        document = create_document(
            self.user,
            make_epub("Cap uno", "Cap dos"),
            file_name="libro.epub",
        )
        response = self.client.post(
            reverse("document-translate", args=[document.pk]),
            {"target_language": "en"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])

    @patch("apps.translations.extractors.MAX_EXTRACTED_PAGES", 1)
    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    def test_pdf_exceeding_page_limit_rejected(self, *mocks):
        document = create_document(self.user, make_pdf("Uno", "Dos"))
        response = self.client.post(
            reverse("document-translate", args=[document.pk]),
            {"target_language": "en"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])


class TranslationThrottleTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.client.force_authenticate(self.user)
        self.document = create_document(self.user, make_pdf("Uno"))

    @patch.object(ScopedRateThrottle, "THROTTLE_RATES", {"translate": "1/min"})
    @patch.object(LibreTranslateClient, "languages", return_value=SUPPORTED_LANGUAGES)
    @patch.object(TranslationService, "start_async")
    def test_translate_throttled_after_limit(self, *mocks):
        cache.clear()
        url = reverse("document-translate", args=[self.document.pk])

        first = self.client.post(url, {"target_language": "en"}, format="json")
        self.assertEqual(first.status_code, status.HTTP_202_ACCEPTED)

        second = self.client.post(url, {"target_language": "es"}, format="json")
        self.assertEqual(second.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertFalse(second.json()["success"])


class _FakeResponse:
    def __init__(self, body):
        self._body = body

    def read(self):
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


class LibreTranslateClientTests(SimpleTestCase):
    def test_default_base_url_uses_settings(self):
        with patch(
            "apps.translations.client.settings.LIBRETRANSLATE_URL",
            "http://lt:5000/",
        ):
            client = LibreTranslateClient()
        self.assertEqual(client.base_url, "http://lt:5000")

    def test_custom_base_url_strips_trailing_slash(self):
        client = LibreTranslateClient(base_url="http://lt:5000/")
        self.assertEqual(client.base_url, "http://lt:5000")

    def test_translate_returns_translated_text(self):
        response = _FakeResponse(b'{"translatedText":"Hola"}')
        with patch("urllib.request.urlopen", return_value=response) as urlopen:
            result = LibreTranslateClient(base_url="http://lt").translate("Hello", "es")

        self.assertEqual(result, "Hola")
        request = urlopen.call_args[0][0]
        self.assertEqual(request.full_url, "http://lt/translate")
        self.assertEqual(request.method, "POST")
        self.assertIn(b'"target": "es"', request.data)

    def test_translate_missing_key_returns_empty(self):
        with patch("urllib.request.urlopen", return_value=_FakeResponse(b"{}")):
            result = LibreTranslateClient(base_url="http://lt").translate("Hello", "es")
        self.assertEqual(result, "")

    def test_languages_uses_get(self):
        with patch(
            "urllib.request.urlopen",
            return_value=_FakeResponse(b"[]"),
        ) as urlopen:
            result = LibreTranslateClient(base_url="http://lt").languages()

        self.assertEqual(result, [])
        request = urlopen.call_args[0][0]
        self.assertEqual(request.full_url, "http://lt/languages")
        self.assertEqual(request.method, "GET")

    def test_connection_error_raises_api_error(self):
        with patch("urllib.request.urlopen", side_effect=TimeoutError("timeout")):
            with self.assertRaises(APIError):
                LibreTranslateClient(base_url="http://lt").translate("Hello", "es")


class ChunkingTests(SimpleTestCase):
    def test_split_handles_word_longer_than_limit(self):
        chunks = split_into_chunks("x" * 1000, max_chars=100)
        self.assertEqual(len(chunks), 10)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 100)

    def test_split_keeps_short_paragraph_whole(self):
        self.assertEqual(split_into_chunks("Hola mundo.", max_chars=100), ["Hola mundo."])

    def test_split_breaks_long_paragraph_by_words(self):
        chunks = split_into_chunks(" ".join(["palabra"] * 100), max_chars=100)
        self.assertGreater(len(chunks), 1)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 100)

    def test_split_handles_oversized_word_after_short_words(self):
        chunks = split_into_chunks("hola " + "x" * 300, max_chars=100)
        self.assertGreater(len(chunks), 1)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 100)


class TranslationServiceEdgeCaseTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.service = TranslationService(client=FakeClient())

    def test_translate_content_blank_returns_empty(self):
        self.assertEqual(self.service._translate_content("   \n ", "auto", "es"), "")

    def test_start_async_spawns_background_thread(self):
        fake_thread = Mock()
        with patch(
            "apps.translations.services.threading.Thread",
            return_value=fake_thread,
        ) as thread_cls:
            self.service.start_async(999)

        thread_cls.assert_called_once_with(
            target=self.service._run_background,
            args=(999,),
            daemon=True,
        )
        fake_thread.start.assert_called_once()

    def test_run_background_processes_translation(self):
        self.service.process = Mock()
        with patch("apps.translations.services.close_old_connections"):
            self.service._run_background(123)
        self.service.process.assert_called_once_with(123)
