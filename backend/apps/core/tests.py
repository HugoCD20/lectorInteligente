from unittest.mock import patch

from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.renderers import BrowsableAPIRenderer, JSONRenderer
from rest_framework.test import APITestCase

from apps.core import views


class HealthCheckTests(APITestCase):
    def test_health_check_returns_consistent_format(self):
        response = self.client.get(reverse("health-check"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertIn("message", body)
        self.assertEqual(body["data"]["status"], "ok")

    @override_settings(DEBUG=True)
    def test_health_check_includes_database_detail_in_debug(self):
        response = self.client.get(reverse("health-check"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["data"]["database"], "ok")

    def test_health_check_hides_database_detail_outside_debug(self):
        response = self.client.get(reverse("health-check"))
        self.assertNotIn("database", response.json()["data"])

    def test_health_check_is_public(self):
        response = self.client.get(reverse("health-check"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)


class ErrorHandlingTests(APITestCase):
    def test_unhandled_drf_error_returns_consistent_format(self):
        url = reverse("health-check")
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertIn("message", body)
        self.assertIn("errors", body)


class RendererSecurityTests(APITestCase):
    def test_json_only_renderer_when_browsable_api_disabled(self):
        with patch.object(views.health_check.cls, "renderer_classes", [JSONRenderer]):
            response = self.client.get(reverse("health-check"), HTTP_ACCEPT="text/html")
            self.assertEqual(response.status_code, status.HTTP_406_NOT_ACCEPTABLE)

    def test_browsable_api_enabled_when_configured(self):
        with patch.object(
            views.health_check.cls,
            "renderer_classes",
            [JSONRenderer, BrowsableAPIRenderer],
        ):
            response = self.client.get(reverse("health-check"), HTTP_ACCEPT="text/html")
            self.assertEqual(response.status_code, status.HTTP_200_OK)
