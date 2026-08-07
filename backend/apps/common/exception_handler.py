import logging

from rest_framework import status
from rest_framework.views import exception_handler as drf_exception_handler

from apps.common.exceptions import APIError
from apps.common.responses import error_response

logger = logging.getLogger("apps.common")


def custom_exception_handler(exc, context):
    """Convierte cualquier excepción en el formato API consistente."""
    if isinstance(exc, APIError):
        return error_response(exc.message, errors=exc.errors, status=exc.status_code)

    response = drf_exception_handler(exc, context)

    if response is not None:
        data = response.data
        if isinstance(data, dict) and "detail" in data:
            message = str(data["detail"])
            errors = {}
        else:
            message = "Datos inválidos."
            errors = data
        return error_response(message, errors=errors, status=response.status_code)

    logger.error("Excepción no controlada: %s", exc, exc_info=exc)
    return error_response(
        "Ocurrió un error interno. Inténtalo nuevamente.",
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
