from django.contrib.auth import get_user_model

User = get_user_model()


class UserRepository:
    """Centraliza las consultas sobre usuarios."""

    def get_by_email(self, email):
        return User.objects.filter(email__iexact=email).first()

    def get_active_by_email(self, email):
        return User.objects.filter(email__iexact=email, is_active=True).first()
