import os
from pathlib import Path

from django.conf import settings
from rest_framework import serializers

PDF_MAGIC = b"%PDF-"
EPUB_MAGIC = b"PK\x03\x04"


def validate_document_extension(value):
    """Valida que la extensión del archivo esté permitida."""
    extension = Path(value.name).suffix.lower().lstrip(".")
    allowed = settings.ALLOWED_DOCUMENT_EXTENSIONS
    if extension not in allowed:
        raise serializers.ValidationError(
            f"Formato no permitido. Formatos válidos: {', '.join(allowed)}."
        )
    return value


def validate_document_size(value):
    """Valida que el archivo no supere el tamaño máximo permitido."""
    if value.size > settings.MAX_DOCUMENT_SIZE:
        raise serializers.ValidationError(
            f"El archivo supera el tamaño máximo de "
            f"{settings.MAX_DOCUMENT_SIZE // (1024 * 1024)} MB."
        )
    return value


def validate_document_content(value):
    """Valida la integridad del archivo mediante sus bytes de cabecera."""
    extension = Path(value.name).suffix.lower().lstrip(".")
    magic = {".pdf": PDF_MAGIC, ".epub": EPUB_MAGIC}.get(f".{extension}")

    if magic is not None:
        try:
            value.seek(0)
            head = value.read(len(magic))
            value.seek(0)
        except OSError:
            raise serializers.ValidationError(
                "El archivo es ilegible o está corrupto."
            )
        if not head.startswith(magic):
            raise serializers.ValidationError(
                "El archivo no coincide con su formato. Verifica el contenido."
            )
    return value


def normalize_original_name(name):
    """Devuelve únicamente el nombre base del archivo."""
    return os.path.basename(name or "documento")
