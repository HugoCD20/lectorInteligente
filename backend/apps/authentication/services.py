from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.core.mail import send_mail
from django.conf import settings
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from apps.common.exceptions import APIError

User = get_user_model()


class AuthService:
    """Lógica de negocio del flujo de autenticación."""

    def register(self, email, password, first_name, last_name):
        user = User.objects.create_user(
            email=_normalize_email(email),
            password=password,
            first_name=first_name,
            last_name=last_name,
        )
        return user, self._tokens_for(user)

    def login(self, email, password):
        user = authenticate(email=_normalize_email(email), password=password)
        if user is None:
            raise APIError("Credenciales inválidas.", status_code=401)
        return user, self._tokens_for(user)

    def logout(self, refresh_token):
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError as exc:
            raise APIError(
                "Token de refresco inválido o ya utilizado.",
                status_code=400,
            ) from exc

    def request_password_reset(self, email):
        user = User.objects.filter(email__iexact=email, is_active=True).first()
        if user is None:
            # Respuesta idéntica para evitar enumeración de usuarios.
            return

        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = PasswordResetTokenGenerator().make_token(user)
        reset_url = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"

        send_mail(
            subject="Restablecimiento de contraseña",
            message=(
                "Recibiste este correo porque solicitaste restablecer tu "
                f"contraseña. Abre el siguiente enlace para continuar:\n\n{reset_url}"
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )

    def confirm_password_reset(self, uid, token, new_password):
        try:
            pk = force_str(urlsafe_base64_decode(uid))
            user = User.objects.get(pk=pk)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist) as exc:
            raise APIError(
                "El enlace de restablecimiento es inválido.",
                status_code=400,
            ) from exc

        if not PasswordResetTokenGenerator().check_token(user, token):
            raise APIError(
                "El enlace de restablecimiento es inválido o ha expirado.",
                status_code=400,
            )

        user.set_password(new_password)
        user.save(update_fields=["password"])
        return user

    @staticmethod
    def _tokens_for(user):
        refresh = RefreshToken.for_user(user)
        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }


def _normalize_email(email):
    """Normaliza el correo a minúsculas para evitar duplicados por mayúsculas."""
    return (email or "").strip().lower()
