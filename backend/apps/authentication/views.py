from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle

from apps.authentication.serializers import (
    LoginSerializer,
    LogoutSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
)
from apps.authentication.services import AuthService
from apps.common.responses import success_response
from apps.users.serializers import UserSerializer


class RegisterView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user, tokens = AuthService().register(
            email=data["email"],
            password=data["password"],
            first_name=data.get("first_name", ""),
            last_name=data.get("last_name", ""),
        )
        return success_response(
            "Usuario creado correctamente.",
            data={"user": UserSerializer(user).data, "tokens": tokens},
            status=status.HTTP_201_CREATED,
        )


class LoginView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user, tokens = AuthService().login(data["email"], data["password"])
        return success_response(
            "Inicio de sesión exitoso.",
            data={"user": UserSerializer(user).data, "tokens": tokens},
        )


class LogoutView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = LogoutSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        AuthService().logout(serializer.validated_data["refresh"])
        return success_response("Sesión cerrada correctamente.")


class PasswordResetRequestView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    serializer_class = PasswordResetRequestSerializer
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        AuthService().request_password_reset(serializer.validated_data["email"])
        return success_response(
            "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña."
        )


class PasswordResetConfirmView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    serializer_class = PasswordResetConfirmSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        AuthService().confirm_password_reset(
            uid=data["uid"],
            token=data["token"],
            new_password=data["new_password"],
        )
        return success_response("Contraseña restablecida correctamente.")
