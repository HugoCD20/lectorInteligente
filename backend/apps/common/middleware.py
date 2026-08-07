import logging
import time

logger = logging.getLogger("apps.common")


class LoggingMiddleware:
    """Registra cada solicitud y su tiempo de respuesta."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.perf_counter()
        path = request.get_full_path()
        method = request.method

        logger.info("Request: %s %s", method, path)
        try:
            response = self.get_response(request)
        except Exception:
            logger.exception("Excepción no controlada: %s %s", method, path)
            raise

        duration_ms = (time.perf_counter() - start) * 1000
        logger.info(
            "Response: %s %s (%d) %.2fms",
            method,
            path,
            response.status_code,
            duration_ms,
        )
        return response
