from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.repositories import UserRepository

User = get_user_model()


def get_tokens(client, email="test@example.com", password="StrongPass123!"):
    response = client.post(
        reverse("token_obtain_pair"),
        {"email": email, "password": password},
        format="json",
    )
    return response.json()["data"]


class ProfileTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
            first_name="Test",
        )
        tokens = get_tokens(self.client)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")

    def test_get_profile(self):
        response = self.client.get(reverse("me"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["id"], self.user.id)
        self.assertEqual(body["data"]["email"], "test@example.com")
        self.assertEqual(body["data"]["first_name"], "Test")

    def test_update_profile(self):
        response = self.client.patch(
            reverse("me"),
            {"first_name": "Nuevo", "last_name": "Apellido"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["first_name"], "Nuevo")
        self.assertEqual(body["data"]["last_name"], "Apellido")

    def test_update_profile_cannot_change_email(self):
        response = self.client.patch(
            reverse("me"),
            {"email": "hacked@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.email, "test@example.com")

    def test_delete_account_soft_deletes(self):
        response = self.client.delete(reverse("me"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

        self.user.refresh_from_db()
        self.assertIsNotNone(self.user.deleted_at)
        self.assertFalse(self.user.is_active)

    def test_deleted_account_cannot_login(self):
        self.client.delete(reverse("me"))
        response = self.client.post(
            reverse("login"),
            {"email": "test@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profile_requires_authentication(self):
        self.client.credentials()
        response = self.client.get(reverse("me"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class ChangePasswordTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        tokens = get_tokens(self.client)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")

    def test_change_password_success(self):
        response = self.client.post(
            reverse("change-password"),
            {
                "current_password": "StrongPass123!",
                "new_password": "NewStrongPass123!",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewStrongPass123!"))

    def test_change_password_wrong_current(self):
        response = self.client.post(
            reverse("change-password"),
            {
                "current_password": "wrong-current",
                "new_password": "NewStrongPass123!",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "La contraseña actual es incorrecta.")

    def test_change_password_requires_authentication(self):
        self.client.credentials()
        response = self.client.post(
            reverse("change-password"),
            {
                "current_password": "StrongPass123!",
                "new_password": "NewStrongPass123!",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserRepositoryTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="Test@Example.com",
            password="StrongPass123!",
        )

    def test_get_by_email_is_case_insensitive(self):
        self.assertEqual(UserRepository().get_by_email("test@example.com"), self.user)

    def test_str_returns_email(self):
        self.assertEqual(str(self.user), "Test@example.com")

    def test_get_by_email_missing_returns_none(self):
        self.assertIsNone(UserRepository().get_by_email("missing@example.com"))

    def test_get_active_by_email_excludes_inactive(self):
        self.user.is_active = False
        self.user.save(update_fields=["is_active"])
        self.assertIsNone(UserRepository().get_active_by_email("test@example.com"))


class UserManagerTests(APITestCase):
    def test_create_user_requires_email(self):
        with self.assertRaises(ValueError):
            User.objects.create_user(email="", password="StrongPass123!")

    def test_create_user_defaults_not_staff_or_superuser(self):
        user = User.objects.create_user(email="normal@example.com", password="StrongPass123!")
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
        self.assertTrue(user.is_active)

    def test_create_superuser_requires_staff(self):
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email="root@example.com",
                password="StrongPass123!",
                is_staff=False,
            )

    def test_create_superuser_requires_superuser_flag(self):
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email="root@example.com",
                password="StrongPass123!",
                is_superuser=False,
            )

    def test_create_superuser_succeeds_with_flags(self):
        user = User.objects.create_superuser(
            email="root@example.com",
            password="StrongPass123!",
        )
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
