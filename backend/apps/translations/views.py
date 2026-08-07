from rest_framework import generics
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle

from apps.common.responses import success_response
from apps.documents.repositories import DocumentRepository
from apps.translations.client import LibreTranslateClient
from apps.translations.models import Translation
from apps.translations.serializers import (
    TranslateRequestSerializer,
    TranslationDetailSerializer,
    TranslationSummarySerializer,
)
from apps.translations.services import TranslationService


def get_document_for_user(user, pk):
    document = DocumentRepository().get_for_user(user, pk)
    if document is None:
        raise NotFound("Documento no encontrado.")
    return document


class TranslateDocumentView(generics.GenericAPIView):
    """Inicia la traducción de un documento propio."""

    permission_classes = [IsAuthenticated]
    serializer_class = TranslateRequestSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "translate"

    def post(self, request, pk):
        document = get_document_for_user(request.user, pk)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target_language = serializer.validated_data["target_language"]

        service = TranslationService()
        _validate_target_language(service, target_language)

        translation, started = service.start(document, target_language)
        if started:
            service.start_async(translation.id)
            return success_response(
                "Traducción iniciada.",
                data=TranslationSummarySerializer(translation).data,
                status=202,
            )
        return success_response(
            "Traducción disponible.",
            data=TranslationSummarySerializer(translation).data,
        )


class DocumentTranslationsView(generics.ListAPIView):
    """Lista las traducciones de un documento propio."""

    permission_classes = [IsAuthenticated]
    serializer_class = TranslationSummarySerializer

    def get_queryset(self):
        document = get_document_for_user(self.request.user, self.kwargs["pk"])
        return Translation.objects.filter(document=document)

    def list(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return success_response(
            "Traducciones obtenidas correctamente.",
            data=serializer.data,
        )


class TranslationDetailView(generics.GenericAPIView):
    """Consulta y eliminación de una traducción de un documento propio."""

    permission_classes = [IsAuthenticated]
    serializer_class = TranslationDetailSerializer

    def _get_translation(self, user, pk, target_language):
        document = get_document_for_user(user, pk)
        translation = Translation.objects.filter(
            document=document,
            target_language=target_language,
        ).first()
        if translation is None:
            raise NotFound("Traducción no encontrada.")
        return translation

    def get(self, request, pk, target_language):
        translation = self._get_translation(request.user, pk, target_language)
        return success_response(
            "Traducción obtenida correctamente.",
            data=TranslationDetailSerializer(translation).data,
        )

    def delete(self, request, pk, target_language):
        translation = self._get_translation(request.user, pk, target_language)
        TranslationService().delete(translation)
        return success_response("Traducción eliminada correctamente.")


class LanguagesView(generics.GenericAPIView):
    """Devuelve los idiomas disponibles en el motor de traducción."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        languages = LibreTranslateClient().languages()
        data = [
            {"code": item["code"], "name": item.get("name", item["code"])}
            for item in languages
        ]
        return success_response("Idiomas obtenidos correctamente.", data=data)


def _validate_target_language(service, target_language):
    codes = {item["code"] for item in service.client.languages()}
    if target_language not in codes:
        raise NotFound(f"Idioma destino no soportado: {target_language}.")
