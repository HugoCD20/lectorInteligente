from django.contrib import admin

from apps.documents.models import Document


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ("id", "original_name", "user", "extension", "file_size", "created_at")
    list_filter = ("extension", "created_at")
    search_fields = ("original_name", "user__email")
    readonly_fields = ("id", "created_at", "updated_at", "deleted_at")
