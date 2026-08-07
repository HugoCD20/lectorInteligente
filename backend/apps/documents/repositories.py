from django.db.models import F, Q

from apps.documents.models import Document

ORDERING_FIELDS = {
    "created_at",
    "-created_at",
    "original_name",
    "-original_name",
}


class DocumentRepository:
    """Centraliza las consultas sobre documentos."""

    def list_for_user(self, user, search=None, ordering=None):
        """Lista los documentos activos del usuario con filtros opcionales."""
        queryset = (
            Document.objects.filter(user=user)
            .prefetch_related("translations")
        )
        if search:
            queryset = queryset.filter(Q(original_name__icontains=search[:100]))
        if ordering in ORDERING_FIELDS:
            queryset = queryset.order_by(ordering)
        return queryset

    def get_for_user(self, user, document_id):
        """Devuelve un documento únicamente si pertenece al usuario."""
        return (
            Document.objects.filter(user=user, id=document_id)
            .prefetch_related("translations")
            .first()
        )

    def get_recent(self, user, limit=None):
        """Devuelve los documentos más recientes del usuario.

        Ordena por última apertura (y por carga cuando aún no se han abierto).
        Prefetch de traducciones para evitar consultas N+1 (el serializer
        incluye las traducciones de cada documento).
        """
        try:
            requested = int(limit)
        except (TypeError, ValueError):
            requested = 5
        limit = max(1, min(requested, 20))
        return (
            Document.objects.filter(user=user)
            .prefetch_related("translations")
            .order_by(
                F("last_opened_at").desc(nulls_last=True),
                "-created_at",
            )[:limit]
        )
