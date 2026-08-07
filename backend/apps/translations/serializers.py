from rest_framework import serializers

from apps.translations.models import Translation, TranslationPage


class TranslateRequestSerializer(serializers.Serializer):
    target_language = serializers.RegexField(
        regex=r"^[a-z]{2,5}$",
        error_messages={"invalid": "Idioma destino inválido."},
    )


class TranslationSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Translation
        fields = [
            "id",
            "source_language",
            "target_language",
            "status",
            "total_pages",
            "processed_pages",
            "failed_pages",
            "updated_at",
        ]
        read_only_fields = fields


class TranslationPageSerializer(serializers.ModelSerializer):
    class Meta:
        model = TranslationPage
        fields = ["page_number", "original_content", "translated_content", "status"]
        read_only_fields = fields


class TranslationDetailSerializer(TranslationSummarySerializer):
    pages = TranslationPageSerializer(many=True, read_only=True)

    class Meta(TranslationSummarySerializer.Meta):
        fields = TranslationSummarySerializer.Meta.fields + ["pages"]
