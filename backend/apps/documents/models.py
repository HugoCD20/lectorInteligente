from django.conf import settings
from django.db import models

from apps.documents.managers import DocumentManager


class Document(models.Model):
    """Documento digital propiedad de un usuario.

    El archivo se almacena mediante el sistema de almacenamiento de Django;
    la base de datos únicamente guarda la referencia. La eliminación es
    lógica (deleted_at) conforme a la política del proyecto.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="documents",
        verbose_name="propietario",
    )
    file = models.FileField(upload_to="documents/%Y/%m/", verbose_name="archivo")
    original_name = models.CharField(max_length=255, verbose_name="nombre original")
    extension = models.CharField(max_length=10, verbose_name="extensión")
    mime_type = models.CharField(max_length=100, verbose_name="tipo MIME")
    file_size = models.BigIntegerField(verbose_name="tamaño en bytes")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="creado en")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="actualizado en")
    last_opened_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="última apertura",
    )
    deleted_at = models.DateTimeField(null=True, blank=True, verbose_name="eliminado en")

    objects = DocumentManager()
    all_objects = models.Manager()

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "documento"
        verbose_name_plural = "documentos"
        indexes = [
            models.Index(fields=["user", "deleted_at"], name="documents_user_deleted_idx"),
            models.Index(fields=["user", "-created_at"], name="documents_user_created_idx"),
            models.Index(
                fields=["user", "-last_opened_at"],
                name="documents_user_opened_idx",
            ),
            models.Index(fields=["original_name"], name="documents_original_name_idx"),
        ]

    def __str__(self):
        return self.original_name
