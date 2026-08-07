from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from apps.common.responses import success_response
from apps.users.serializers import (
    ChangePasswordSerializer,
    UpdateProfileSerializer,
    UserSerializer,
)
from apps.users.services import UserService


class MeView(generics.GenericAPIView):
    """Consulta, actualización y eliminación del perfil propio."""

    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get(self, request):
        return success_response(
            "Perfil obtenido correctamente.",
            data=UserSerializer(request.user).data,
        )

    def patch(self, request):
        serializer = UpdateProfileSerializer(
            request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)

        user = UserService().update_profile(request.user, serializer.validated_data)
        return success_response(
            "Perfil actualizado correctamente.",
            data=UserSerializer(user).data,
        )

    def delete(self, request):
        UserService().soft_delete(request.user)
        return success_response("Cuenta eliminada correctamente.")


class ChangePasswordView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ChangePasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        UserService().change_password(
            request.user,
            current_password=data["current_password"],
            new_password=data["new_password"],
        )
        return success_response("Contraseña actualizada correctamente.")
