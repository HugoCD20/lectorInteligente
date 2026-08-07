from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)

from apps.common.responses import success_response


class CustomTokenObtainPairView(TokenObtainPairView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        return success_response("Autenticación exitosa.", data=response.data)


class CustomTokenRefreshView(TokenRefreshView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        return success_response("Token actualizado.", data=response.data)


class CustomTokenVerifyView(TokenVerifyView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        return success_response("Token válido.", data=response.data)
