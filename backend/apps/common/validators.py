from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers


def password_validator(value):
    """Valida una contraseña usando los validadores configurados de Django."""
    try:
        validate_password(value)
    except DjangoValidationError as exc:
        raise serializers.ValidationError(list(exc.messages))
