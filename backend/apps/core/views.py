from django.conf import settings
from django.db import connection
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny

from apps.common.responses import success_response


@api_view(["GET"])
@permission_classes([AllowAny])
def health_check(request):
    """Verifica la disponibilidad del servicio y su conexión a la base de datos."""
    db_status = "ok"
    try:
        connection.ensure_connection()
    except Exception:
        db_status = "error"

    data = {"status": db_status}
    if settings.DEBUG:
        data["database"] = db_status
    return success_response(
        "Servicio disponible.",
        data=data,
    )
