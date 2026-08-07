from django.utils import timezone

from apps.common.exceptions import APIError


class UserService:
    """Lógica de negocio de la gestión del perfil del usuario."""

    def update_profile(self, user, validated_data):
        for field, value in validated_data.items():
            setattr(user, field, value)
        user.save(update_fields=list(validated_data.keys()))
        return user

    def change_password(self, user, current_password, new_password):
        if not user.check_password(current_password):
            raise APIError("La contraseña actual es incorrecta.", status_code=400)
        user.set_password(new_password)
        user.save(update_fields=["password"])
        return user

    def soft_delete(self, user):
        """Elimina lógicamente la cuenta del usuario."""
        user.deleted_at = timezone.now()
        user.is_active = False
        user.save(update_fields=["deleted_at", "is_active"])
        return user
