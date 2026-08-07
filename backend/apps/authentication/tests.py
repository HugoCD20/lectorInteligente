from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework.throttling import ScopedRateThrottle

User = get_user_model()


def get_tokens(client, email="test@example.com", password="StrongPass123!"):
    response = client.post(
        reverse("token_obtain_pair"),
        {"email": email, "password": password},
        format="json",
    )
    return response.json()["data"]


class RegisterTests(APITestCase):
    def test_register_success(self):
        response = self.client.post(
            reverse("register"),
            {
                "email": "new@example.com",
                "password": "StrongPass123!",
                "first_name": "Ana",
                "last_name": "García",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["user"]["email"], "new@example.com")
        self.assertIn("access", body["data"]["tokens"])
        self.assertIn("refresh", body["data"]["tokens"])

    def test_register_duplicate_email(self):
        User.objects.create_user(email="dup@example.com", password="StrongPass123!")
        response = self.client.post(
            reverse("register"),
            {"email": "dup@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertIn("email", body["errors"])

    def test_register_invalid_email(self):
        response = self.client.post(
            reverse("register"),
            {"email": "invalid", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])

    def test_register_normalizes_email_to_lowercase(self):
        response = self.client.post(
            reverse("register"),
            {"email": "  Mixed@Example.COM ", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()["data"]["user"]["email"], "mixed@example.com")
        self.assertTrue(User.objects.filter(email="mixed@example.com").exists())


class LoginTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
            first_name="Test",
        )

    def test_login_success(self):
        response = self.client.post(
            reverse("login"),
            {"email": "test@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["user"]["email"], "test@example.com")
        self.assertIn("access", body["data"]["tokens"])

    def test_login_invalid_credentials(self):
        response = self.client.post(
            reverse("login"),
            {"email": "test@example.com", "password": "wrong"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertIn("message", body)

    def test_login_email_is_case_insensitive(self):
        response = self.client.post(
            reverse("login"),
            {"email": "Test@Example.COM", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])


class ThrottleTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )

    @patch.object(ScopedRateThrottle, "THROTTLE_RATES", {"auth": "1/min"})
    def test_login_throttled_after_limit(self):
        cache.clear()
        url = reverse("login")
        payload = {"email": "test@example.com", "password": "wrong"}

        first = self.client.post(url, payload, format="json")
        self.assertEqual(first.status_code, status.HTTP_401_UNAUTHORIZED)

        second = self.client.post(url, payload, format="json")
        self.assertEqual(second.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertFalse(second.json()["success"])


class LogoutTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        self.tokens = get_tokens(self.client)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.tokens['access']}")

    def test_logout_success(self):
        response = self.client.post(
            reverse("logout"),
            {"refresh": self.tokens["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

    def test_logout_requires_authentication(self):
        self.client.credentials()
        response = self.client.post(
            reverse("logout"),
            {"refresh": "anything"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(response.json()["success"])

    def test_logout_blacklists_refresh_token(self):
        self.client.post(reverse("logout"), {"refresh": self.tokens["refresh"]}, format="json")

        response = self.client.post(
            reverse("token_refresh"),
            {"refresh": self.tokens["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class PasswordResetTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )

    def test_password_reset_request_sends_email(self):
        response = self.client.post(
            reverse("password-reset"),
            {"email": "test@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn("reset-password", mail.outbox[0].body)

    def test_password_reset_request_unknown_email_returns_same_message(self):
        response = self.client.post(
            reverse("password-reset"),
            {"email": "unknown@example.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])
        self.assertEqual(len(mail.outbox), 0)

    def test_password_reset_confirm_success(self):
        from django.contrib.auth.tokens import PasswordResetTokenGenerator
        from django.utils.encoding import force_bytes
        from django.utils.http import urlsafe_base64_encode

        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        token = PasswordResetTokenGenerator().make_token(self.user)

        response = self.client.post(
            reverse("password-reset-confirm"),
            {"uid": uid, "token": token, "new_password": "NewStrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])

        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewStrongPass123!"))

    def test_password_reset_confirm_invalid_token(self):
        from django.utils.encoding import force_bytes
        from django.utils.http import urlsafe_base64_encode

        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        response = self.client.post(
            reverse("password-reset-confirm"),
            {"uid": uid, "token": "invalid-token", "new_password": "NewStrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.json()["success"])


class JwtEndpointTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )

    def test_obtain_token_success(self):
        response = self.client.post(
            reverse("token_obtain_pair"),
            {"email": "test@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertIn("access", body["data"])

    def test_obtain_token_invalid_credentials(self):
        response = self.client.post(
            reverse("token_obtain_pair"),
            {"email": "test@example.com", "password": "wrong"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(response.json()["success"])

    def test_refresh_token_success(self):
        tokens = get_tokens(self.client)
        response = self.client.post(
            reverse("token_refresh"),
            {"refresh": tokens["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.json()["data"])

    def test_verify_valid_token(self):
        tokens = get_tokens(self.client)
        response = self.client.post(
            reverse("token_verify"),
            {"token": tokens["access"]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["success"])


class ProtectedEndpointTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )

    def test_profile_requires_authentication(self):
        response = self.client.get(reverse("me"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(response.json()["success"])

    def test_profile_with_valid_token(self):
        tokens = get_tokens(self.client)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        response = self.client.get(reverse("me"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["data"]["id"], self.user.id)
        self.assertEqual(body["data"]["email"], "test@example.com")


class LogoutErrorPathTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )
        tokens = get_tokens(self.client)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")

    def test_logout_with_invalid_refresh_token(self):
        response = self.client.post(
            reverse("logout"),
            {"refresh": "token-invalido"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "Token de refresco inválido o ya utilizado.")


class PasswordResetErrorPathTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com",
            password="StrongPass123!",
        )

    def test_password_reset_confirm_invalid_uid(self):
        response = self.client.post(
            reverse("password-reset-confirm"),
            {
                "uid": "uid-no-valido",
                "token": "token",
                "new_password": "NewStrongPass123!",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "El enlace de restablecimiento es inválido.")
