from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.common.responses import error_response, success_response


class ResponseHelpersTests(APITestCase):
    def test_success_response_format(self):
        response = success_response("Operación exitosa.", data={"id": 1})
        body = response.data
        self.assertTrue(body["success"])
        self.assertEqual(body["message"], "Operación exitosa.")
        self.assertEqual(body["data"], {"id": 1})

    def test_success_response_default_data(self):
        response = success_response("Operación exitosa.")
        self.assertEqual(response.data["data"], {})

    def test_error_response_format(self):
        response = error_response("Error de validación.", errors={"email": ["Ya existe."]}, status=400)
        body = response.data
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "Error de validación.")
        self.assertEqual(body["errors"], {"email": ["Ya existe."]})

    def test_error_response_default_errors(self):
        response = error_response("Error interno.")
        self.assertEqual(response.data["errors"], {})


class ErrorHandlingTests(APITestCase):
    def test_unhandled_drf_error_returns_consistent_format(self):
        url = reverse("health-check")
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        body = response.json()
        self.assertFalse(body["success"])
        self.assertIn("message", body)
        self.assertIn("errors", body)
