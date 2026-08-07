from django.http import FileResponse
from rest_framework import generics
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated

from apps.common.pagination import StandardPagination
from apps.common.responses import success_response
from apps.documents.reading import ReadingService
from apps.documents.repositories import DocumentRepository
from apps.documents.serializers import (
    DocumentSerializer,
    DocumentUploadSerializer,
)
from apps.documents.services import DocumentService


class DocumentUploadView(generics.GenericAPIView):
    """Subida de un nuevo documento."""

    permission_classes = [IsAuthenticated]
    serializer_class = DocumentUploadSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        document = DocumentService().upload(
            request.user,
            serializer.validated_data["file"],
        )
        return success_response(
            "Documento subido correctamente.",
            data=DocumentSerializer(
                document,
                context={"request": request},
            ).data,
            status=201,
        )


class GalleryView(generics.ListAPIView):
    """Galería de documentos del usuario autenticado con búsqueda y paginación."""

    permission_classes = [IsAuthenticated]
    serializer_class = DocumentSerializer
    pagination_class = StandardPagination

    def get_queryset(self):
        return DocumentRepository().list_for_user(
            self.request.user,
            search=self.request.query_params.get("search"),
            ordering=self.request.query_params.get("ordering"),
        )

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            data = self.get_paginated_response(serializer.data)
        else:
            serializer = self.get_serializer(queryset, many=True)
            data = {"count": len(serializer.data), "results": serializer.data}
        return success_response(
            "Galería obtenida correctamente.",
            data=data,
        )


class RecentDocumentsView(generics.ListAPIView):
    """Documentos más recientes del usuario autenticado."""

    permission_classes = [IsAuthenticated]
    serializer_class = DocumentSerializer

    def get_queryset(self):
        return DocumentRepository().get_recent(
            self.request.user,
            self.request.query_params.get("limit"),
        )

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return success_response(
            "Documentos recientes obtenidos correctamente.",
            data=serializer.data,
        )


class DocumentReadView(generics.GenericAPIView):
    """Lectura de un documento propio: páginas originales y traducidas.

    Registra la apertura en el historial reciente y devuelve únicamente la
    ventana de páginas solicitada (carga eficiente).
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        document = DocumentRepository().get_for_user(request.user, pk)
        if document is None:
            raise NotFound("Documento no encontrado.")

        page = _parse_int(request.query_params.get("page"), default=1, minimum=1)
        page_size = _parse_int(
            request.query_params.get("page_size"),
            default=1,
            minimum=1,
            maximum=20,
        )
        if page == 1:
            DocumentService().open(document)
        data = ReadingService().read(
            document,
            page=page,
            page_size=page_size,
            target_language=request.query_params.get("target_language") or None,
        )
        return success_response("Páginas obtenidas correctamente.", data=data)


def _parse_int(raw, default, minimum, maximum=None):
    try:
        value = int(raw)
    except (TypeError, ValueError):
        return default
    value = max(value, minimum)
    if maximum is not None:
        value = min(value, maximum)
    return value


class DocumentFileView(generics.GenericAPIView):
    """Descarga del archivo original, únicamente para el propietario.

    Reemplaza el acceso directo a la carpeta de medios, que no debe estar
    expuesta de forma pública.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        document = DocumentRepository().get_for_user(request.user, pk)
        if document is None:
            raise NotFound("Documento no encontrado.")
        response = FileResponse(
            document.file.open("rb"),
            as_attachment=True,
            filename=document.original_name,
        )
        return response


class DocumentDetailView(generics.GenericAPIView):
    """Consulta y eliminación de un documento propio."""

    permission_classes = [IsAuthenticated]
    serializer_class = DocumentSerializer

    def get_object(self):
        document = DocumentRepository().get_for_user(
            self.request.user,
            self.kwargs["pk"],
        )
        if document is None:
            raise NotFound("Documento no encontrado.")
        return document

    def get(self, request, pk):
        document = self.get_object()
        return success_response(
            "Documento obtenido correctamente.",
            data=DocumentSerializer(
                document,
                context={"request": request},
            ).data,
        )

    def delete(self, request, pk):
        document = self.get_object()
        DocumentService().soft_delete(document)
        return success_response("Documento eliminado correctamente.")
