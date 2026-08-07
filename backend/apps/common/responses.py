from rest_framework.response import Response


def success_response(message, data=None, status=200):
    """Devuelve una respuesta exitosa con el formato API consistente."""
    return Response(
        {
            "success": True,
            "message": message,
            "data": data if data is not None else {},
        },
        status=status,
    )


def error_response(message, errors=None, status=400):
    """Devuelve una respuesta de error con el formato API consistente."""
    return Response(
        {
            "success": False,
            "message": message,
            "errors": errors if errors is not None else {},
        },
        status=status,
    )
