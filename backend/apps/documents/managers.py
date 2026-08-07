from django.db import models


class DocumentManager(models.Manager):
    """Gestor por defecto: excluye los documentos eliminados lógicamente."""

    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)
