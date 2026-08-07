from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("translations", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="translation",
            name="source_version",
            field=models.CharField(
                blank=True,
                default="",
                max_length=255,
                verbose_name="versión del documento de origen",
            ),
        ),
    ]
