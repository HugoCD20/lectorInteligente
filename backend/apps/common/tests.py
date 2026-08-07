from types import SimpleNamespace
from unittest.mock import Mock, patch

from django.test import RequestFactory, SimpleTestCase
from django.urls import reverse
from rest_framework import serializers, status
from rest_framework.test import APITestCase

from apps.common.exception_handler import custom_exception_handler
from apps.common.middleware import LoggingMiddleware
from apps.common.pagination import StandardPagination
from apps.common.responses import error_response, success_response
from apps.common.validators import password_validator


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


class LoggingMiddlewareTests(SimpleTestCase):
    def setUp(self):
        self.factory = RequestFactory()

    def test_logs_request_and_response(self):
        get_response = Mock(return_value=Mock(status_code=200))
        middleware = LoggingMiddleware(get_response)

        with patch("apps.common.middleware.logger") as logger:
            response = middleware(self.factory.get("/api/health/"))

        self.assertEqual(response.status_code, 200)
        logger.info.assert_any_call("Request: %s %s", "GET", "/api/health/")
        self.assertEqual(logger.info.call_count, 2)

    def test_logs_exception_and_reraises(self):
        def get_response(request):
            raise ValueError("boom")

        middleware = LoggingMiddleware(get_response)

        with patch("apps.common.middleware.logger") as logger:
            with self.assertRaises(ValueError):
                middleware(self.factory.get("/api/documents/"))

        logger.exception.assert_called_once()


class StandardPaginationTests(SimpleTestCase):
    def test_paginated_response_includes_meta(self):
        paginator = StandardPagination()
        paginator.request = SimpleNamespace(query_params={"page_size": "5"})
        paginator.page = SimpleNamespace(
            paginator=SimpleNamespace(count=23),
            number=2,
        )
        paginator.get_next_link = lambda: "http://testserver/api/documents/?page=3"
        paginator.get_previous_link = lambda: "http://testserver/api/documents/?page=1"

        data = paginator.get_paginated_response(["a", "b"])

        self.assertEqual(data["count"], 23)
        self.assertEqual(data["page"], 2)
        self.assertEqual(data["page_size"], 5)
        self.assertEqual(data["next"], "http://testserver/api/documents/?page=3")
        self.assertEqual(data["previous"], "http://testserver/api/documents/?page=1")
        self.assertEqual(data["results"], ["a", "b"])


class PasswordValidatorTests(SimpleTestCase):
    def test_accepts_strong_password(self):
        self.assertIsNone(password_validator("Str0ng!Passw0rd"))

    def test_rejects_weak_password_with_error_list(self):
        with self.assertRaises(serializers.ValidationError) as context:
            password_validator("1234")
        self.assertIsInstance(context.exception.detail, list)
        self.assertTrue(context.exception.detail)


class ExceptionHandlerTests(SimpleTestCase):
    def test_unhandled_exception_returns_500_consistent_format(self):
        with patch("apps.common.exception_handler.logger"):
            response = custom_exception_handler(ValueError("boom"), {})

        self.assertEqual(response.status_code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        body = response.data
        self.assertFalse(body["success"])
        self.assertEqual(body["message"], "Ocurrió un error interno. Inténtalo nuevamente.")
        self.assertEqual(body["errors"], {})
