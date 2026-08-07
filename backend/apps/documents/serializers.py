from django.urls import reverse
from rest_framework import serializers

from apps.documents.models import Document
from apps.documents.validators import (
    validate_document_content,
    validate_document_extension,
    validate_document_size,
)
from apps.translations.serializers import TranslationSummarySerializer


class DocumentSerializer(serializers.ModelSerializer):
    file = serializers.SerializerMethodField()
    translations = TranslationSummarySerializer(many=True, read_only=True)

    class Meta:
        model = Document
        fields = [
            "id",
            "original_name",
            "extension",
            "mime_type",
            "file_size",
            "file",
            "created_at",
            "translations",
        ]
        read_only_fields = fields

    def get_file(self, obj):
        url = reverse("document-file", args=[obj.pk])
        request = self.context.get("request")
        if request is not None:
            return request.build_absolute_uri(url)
        return url


class DocumentUploadSerializer(serializers.Serializer):
    file = serializers.FileField(
        validators=[
            validate_document_extension,
            validate_document_size,
            validate_document_content,
        ]
    )
