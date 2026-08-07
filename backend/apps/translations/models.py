from django.db import models


class TranslationManager(models.Manager):
    """Gestor por defecto: excluye las traducciones eliminadas lógicamente."""

    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)


class Translation(models.Model):
    """Traducción de un documento a un idioma destino.

    Cada documento puede tener una única traducción activa por idioma
    destino. Las páginas traducidas se almacenan en [TranslationPage].
    """

    class Status(models.TextChoices):
        PENDING = "pending", "Pendiente"
        PROCESSING = "processing", "En proceso"
        COMPLETED = "completed", "Completada"
        PARTIAL = "partial", "Completa con errores"
        FAILED = "failed", "Fallida"

    document = models.ForeignKey(
        "documents.Document",
        on_delete=models.CASCADE,
        related_name="translations",
        verbose_name="documento",
    )
    source_language = models.CharField(max_length=10, default="auto", verbose_name="idioma origen")
    target_language = models.CharField(max_length=10, verbose_name="idioma destino")
    source_version = models.CharField(
        max_length=255,
        blank=True,
        default="",
        verbose_name="versión del documento de origen",
    )
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name="estado",
    )
    total_pages = models.PositiveIntegerField(default=0, verbose_name="páginas totales")
    processed_pages = models.PositiveIntegerField(default=0, verbose_name="páginas procesadas")
    failed_pages = models.PositiveIntegerField(default=0, verbose_name="páginas fallidas")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="creado en")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="actualizado en")
    deleted_at = models.DateTimeField(null=True, blank=True, verbose_name="eliminado en")

    objects = TranslationManager()
    all_objects = models.Manager()

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "traducción"
        verbose_name_plural = "traducciones"
        constraints = [
            models.UniqueConstraint(
                fields=["document", "target_language"],
                condition=models.Q(deleted_at__isnull=True),
                name="translations_active_unique",
            ),
        ]
        indexes = [
            models.Index(fields=["document", "status"], name="translations_doc_status_idx"),
        ]

    def __str__(self):
        return f"{self.document_id} -> {self.target_language} ({self.status})"


class TranslationPage(models.Model):
    """Página traducida de una traducción."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pendiente"
        COMPLETED = "completed", "Completada"
        FAILED = "failed", "Fallida"

    translation = models.ForeignKey(
        Translation,
        on_delete=models.CASCADE,
        related_name="pages",
        verbose_name="traducción",
    )
    page_number = models.PositiveIntegerField(verbose_name="número de página")
    original_content = models.TextField(verbose_name="contenido original")
    translated_content = models.TextField(default="", blank=True, verbose_name="contenido traducido")
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.PENDING,
        verbose_name="estado",
    )
    error_message = models.TextField(default="", blank=True, verbose_name="mensaje de error")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="creado en")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="actualizado en")

    class Meta:
        ordering = ["page_number"]
        verbose_name = "página de traducción"
        verbose_name_plural = "páginas de traducción"
        constraints = [
            models.UniqueConstraint(
                fields=["translation", "page_number"],
                name="translation_pages_unique",
            ),
        ]

    def __str__(self):
        return f"página {self.page_number} de {self.translation_id}"
