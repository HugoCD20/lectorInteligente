from django.contrib.postgres.operations import TrigramExtension
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("documents", "0002_document_last_opened_at_and_more"),
    ]

    operations = [
        TrigramExtension(),
        migrations.RunSQL(
            sql=(
                "CREATE INDEX documents_original_name_trgm_idx "
                "ON documents_document USING gin "
                "(UPPER(original_name) gin_trgm_ops);"
            ),
            reverse_sql=(
                "DROP INDEX IF EXISTS documents_original_name_trgm_idx;"
            ),
        ),
    ]
