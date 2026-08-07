import tempfile

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.documents.models import Document
from apps.documents.services import DocumentService

User = get_user_model()

PDF_BYTES = b"%PDF-1.4\n% contenido de prueba\n%%EOF"
EPUB_BYTES = b"PK\x03\x04 contenido de prueba epub"


def make_pdf(name="libro.pdf"):
    return SimpleUploadedFile(name, PDF_BYTES, content_type="application/pdf")


def create_document(user, original_name, **kwargs):
    return Document.objects.create(
        user=user,
        file=f"documents/2026/01/{original_name}",
        original_name=original_name,
        extension=original_name.rsplit(".", 1)[-1].lower(),
        mime_type="application/pdf",
        file_size=1024,
        **kwargs,
    )


class DocumentUploadTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.client.force_authenticate(self.user)

    def test_upload_pdf_success(self):
        response = self.client.post(
            reverse("document-upload"),
            {"file": make_pdf()},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["original_name"], "libro.pdf")
        self.assertEqual(body["data"]["extension"], "pdf")
        self.assertTrue(Document.objects.filter(user=self.user).exists())

    def test_upload_epub_success(self):
        response = self.client.post(
            reverse("document-upload"),
            {"file": SimpleUploadedFile("libro.epub", EPUB_BYTES, content_type="application/epub+zip")},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()["data"]["extension"], "epub")

    def test_upload_invalid_extension(self):
        response = self.client.post(
            reverse("document-upload"),
            {"file": SimpleUploadedFile("virus.exe", b"MZ...", content_type="application/octet-stream")},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])

    def test_upload_content_mismatch(self):
        response = self.client.post(
            reverse("document-upload"),
            {"file": SimpleUploadedFile("fake.pdf", b"not a real pdf", content_type="application/pdf")},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])

    def test_upload_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.post(
            reverse("document-upload"),
            {"file": make_pdf()},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class DocumentOversizeTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.client.force_authenticate(self.user)

    @override_settings(MAX_DOCUMENT_SIZE=1024)
    def test_upload_oversize_rejected(self):
        big = SimpleUploadedFile(
            "grande.pdf",
            b"%PDF-" + b"a" * 2048,
            content_type="application/pdf",
        )
        response = self.client.post(
            reverse("document-upload"),
            {"file": big},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])


class GalleryTests(APITestCase):
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
        self.doc_a = create_document(self.user, "algoritmos.pdf")
        self.doc_b = create_document(self.user, "historia.pdf")
        create_document(self.other, "privado.pdf")

    def test_gallery_returns_only_own_documents(self):
        response = self.client.get(reverse("documents-gallery"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["count"], 2)
        names = {item["original_name"] for item in body["data"]["results"]}
        self.assertEqual(names, {"algoritmos.pdf", "historia.pdf"})

    def test_gallery_search_filters(self):
        response = self.client.get(reverse("documents-gallery"), {"search": "historia"})
        body = response.json()
        self.assertEqual(body["data"]["count"], 1)
        self.assertEqual(body["data"]["results"][0]["original_name"], "historia.pdf")

    def test_gallery_search_capped_length(self):
        response = self.client.get(reverse("documents-gallery"), {"search": "a" * 500})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

    def test_gallery_pagination(self):
        for i in range(5):
            create_document(self.user, f"doc{i}.pdf")
        response = self.client.get(reverse("documents-gallery"), {"page_size": 2})
        body = response.json()
        self.assertEqual(body["data"]["count"], 7)
        self.assertEqual(body["data"]["page"], 1)
        self.assertEqual(len(body["data"]["results"]), 2)
        self.assertIsNotNone(body["data"]["next"])

    def test_gallery_excludes_deleted_documents(self):
        Document.objects.filter(pk=self.doc_b.pk).update(deleted_at="2026-01-01T00:00:00Z")
        response = self.client.get(reverse("documents-gallery"))
        body = response.json()
        self.assertEqual(body["data"]["count"], 1)
        names = {item["original_name"] for item in body["data"]["results"]}
        self.assertEqual(names, {"algoritmos.pdf"})

    def test_gallery_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(reverse("documents-gallery"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class RecentDocumentsTests(APITestCase):
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

    def test_recent_returns_own_documents_ordered(self):
        create_document(self.user, "uno.pdf")
        create_document(self.user, "dos.pdf")
        create_document(self.other, "ajeno.pdf")
        response = self.client.get(reverse("documents-recent"), {"limit": 1})
        body = response.json()
        self.assertEqual(len(body["data"]), 1)
        self.assertEqual(body["data"][0]["original_name"], "dos.pdf")

    def test_recent_caps_limit(self):
        for i in range(30):
            create_document(self.user, f"doc{i}.pdf")
        response = self.client.get(reverse("documents-recent"), {"limit": 999})
        self.assertEqual(len(response.json()["data"]), 20)

    def test_recent_negative_limit_clamped(self):
        create_document(self.user, "uno.pdf")
        create_document(self.user, "dos.pdf")
        response = self.client.get(reverse("documents-recent"), {"limit": -5})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()["data"]), 1)

    def test_recent_prefetches_translations(self):
        from django.test.utils import CaptureQueriesContext
        from django.db import connection

        create_document(self.user, "uno.pdf")
        create_document(self.user, "dos.pdf")
        with CaptureQueriesContext(connection) as context:
            self.client.get(reverse("documents-recent"))
        self.assertEqual(len(context), 2)


class DocumentDetailTests(APITestCase):
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
        self.document = create_document(self.user, "algoritmos.pdf")

    def test_detail_returns_own_document(self):
        response = self.client.get(reverse("document-detail", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])
        self.assertEqual(response.json()["data"]["id"], self.document.pk)

    def test_detail_hides_other_users_document(self):
        response = self.client.get(
            reverse("document-detail", args=[99999]),
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(response.json()["success"])

    def test_delete_soft_deletes_document(self):
        response = self.client.delete(reverse("document-detail", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

        self.document.refresh_from_db()
        self.assertIsNotNone(self.document.deleted_at)
        self.assertFalse(Document.objects.filter(pk=self.document.pk).exists())
        self.assertTrue(Document.all_objects.filter(pk=self.document.pk).exists())

    def test_deleted_document_not_accessible(self):
        self.client.delete(reverse("document-detail", args=[self.document.pk]))
        response = self.client.get(reverse("document-detail", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_non_owner_cannot_delete(self):
        self.client.force_authenticate(self.other)
        response = self.client.delete(reverse("document-detail", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Document.objects.filter(pk=self.document.pk).exists())


def make_readable_pdf(*page_texts, name="libro.pdf"):
    import io

    from pypdf import PdfWriter
    from pypdf.generic import DecodedStreamObject, DictionaryObject, NameObject

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
    return SimpleUploadedFile(name, buffer.read(), content_type="application/pdf")


class FakeTranslateClient:
    def translate(self, text, target_language, source_language="auto"):
        return f"[{target_language}] {text}"

    def languages(self):
        return [
            {"code": "en", "name": "English"},
            {"code": "es", "name": "Spanish"},
        ]


class DocumentReadingTests(APITestCase):
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
        self.document = DocumentService().upload(
            self.user,
            make_readable_pdf("Hola uno", "Hola dos", "Hola tres"),
        )

    def _translate(self, document, target_language="es"):
        from apps.translations.services import TranslationService

        service = TranslationService(client=FakeTranslateClient())
        translation, _ = service.start(document, target_language)
        service.process(translation.id)

    def test_read_returns_page_window(self):
        response = self.client.get(
            reverse("document-read", args=[self.document.pk]),
            {"page": 2, "page_size": 2},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()["data"]
        self.assertEqual(body["total_pages"], 3)
        self.assertEqual(body["page"], 2)
        self.assertEqual([p["page_number"] for p in body["pages"]], [2, 3])
        self.assertEqual(body["pages"][0]["original_content"], "Hola dos")

    def test_read_clamps_page_out_of_range(self):
        response = self.client.get(
            reverse("document-read", args=[self.document.pk]),
            {"page": 99},
        )
        body = response.json()["data"]
        self.assertEqual(body["page"], 3)

        response = self.client.get(
            reverse("document-read", args=[self.document.pk]),
            {"page": 0},
        )
        self.assertEqual(response.json()["data"]["page"], 1)

    def test_read_includes_translation_when_requested(self):
        self._translate(self.document)
        response = self.client.get(
            reverse("document-read", args=[self.document.pk]),
            {"page": 1, "target_language": "es"},
        )
        body = response.json()["data"]
        self.assertEqual(body["target_language"], "es")
        self.assertEqual(body["translation"]["target_language"], "es")
        self.assertEqual(body["pages"][0]["translated_content"], "[es] Hola uno")

    def test_read_without_translation_leaves_translated_content_null(self):
        self._translate(self.document)
        response = self.client.get(
            reverse("document-read", args=[self.document.pk]),
            {"page": 1, "target_language": "xx"},
        )
        body = response.json()["data"]
        self.assertIsNone(body["translation"])
        self.assertIsNone(body["pages"][0].get("translated_content"))

    def test_read_registers_opening_on_first_page(self):
        self.document.last_opened_at = "2026-01-01T00:00:00Z"
        self.document.save(update_fields=["last_opened_at"])
        self.client.get(reverse("document-read", args=[self.document.pk]))
        self.document.refresh_from_db()
        opened = self.document.last_opened_at
        self.assertIsNotNone(opened)

        self.client.get(reverse("document-read", args=[self.document.pk]), {"page": 2})
        self.document.refresh_from_db()
        self.assertEqual(self.document.last_opened_at, opened)

    def test_read_only_owner_can_read(self):
        self.client.force_authenticate(self.other)
        response = self.client.get(reverse("document-read", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_read_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(reverse("document-read", args=[self.document.pk]))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_recent_orders_by_last_opened(self):
        first = DocumentService().upload(
            self.user, make_readable_pdf("Primero", name="Primero.pdf")
        )
        second = DocumentService().upload(
            self.user, make_readable_pdf("Segundo", name="Segundo.pdf")
        )

        DocumentService().open(first)
        response = self.client.get(reverse("documents-recent"))
        names = [item["original_name"] for item in response.json()["data"]]
        self.assertEqual(names[0], "Primero.pdf")
        self.assertEqual(names[1], "Segundo.pdf")


@override_settings(MEDIA_ROOT=tempfile.mkdtemp(prefix="lector_test_media_"))
class DocumentFileTests(APITestCase):
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
        self.document = DocumentService().upload(
            self.user,
            make_readable_pdf("Contenido", name="algoritmos.pdf"),
        )

    def test_download_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(
            reverse("document-file", args=[self.document.pk])
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_download_hidden_for_other_user(self):
        self.client.force_authenticate(self.other)
        response = self.client.get(
            reverse("document-file", args=[self.document.pk])
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(response.json()["success"])

    def test_download_returns_attachment_for_owner(self):
        response = self.client.get(
            reverse("document-file", args=[self.document.pk])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        disposition = response["Content-Disposition"]
        self.assertEqual(disposition.split(";")[0].strip(), "attachment")
        self.assertIn("algoritmos.pdf", disposition)
        content = b"".join(response.streaming_content)
        self.assertTrue(content.startswith(b"%PDF-"))

    def test_serializer_exposes_protected_file_url(self):
        response = self.client.get(
            reverse("document-detail", args=[self.document.pk])
        )
        url = response.json()["data"]["file"]
        self.assertIn(f"/api/documents/{self.document.pk}/file/", url)
        self.assertNotIn("/media/", url)

    def test_media_directory_not_publicly_served(self):
        response = self.client.get(f"/media/{self.document.file.name}")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
