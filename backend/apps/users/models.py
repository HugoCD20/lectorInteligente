from django.contrib.auth.models import AbstractUser
from django.db import models

from apps.users.managers import UserManager


class User(AbstractUser):
    """Usuario del sistema con identificación por email.

    El usuario utiliza eliminación lógica (deleted_at) conforme a la
    política de borrado del proyecto.
    """

    username = None

    email = models.EmailField(unique=True, verbose_name="email")
    deleted_at = models.DateTimeField(null=True, blank=True, verbose_name="eliminado en")

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        ordering = ["-date_joined"]
        verbose_name = "usuario"
        verbose_name_plural = "usuarios"

    def __str__(self):
        return self.email
