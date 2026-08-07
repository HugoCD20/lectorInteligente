import json
import urllib.request

from django.conf import settings

from apps.common.exceptions import APIError


class LibreTranslateClient:
    """Cliente HTTP del motor de traducción LibreTranslate."""

    def __init__(self, base_url=None):
        self.base_url = (base_url or settings.LIBRETRANSLATE_URL).rstrip("/")

    def translate(self, text, target_language, source_language="auto"):
        payload = {
            "q": text,
            "source": source_language,
            "target": target_language,
            "format": "text",
        }
        data = self._post("/translate", payload)
        return data.get("translatedText", "")

    def languages(self):
        return self._get("/languages")

    def _post(self, path, payload):
        body = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            self.base_url + path,
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        return self._request(request)

    def _get(self, path):
        return self._request(urllib.request.Request(self.base_url + path, method="GET"))

    def _request(self, request):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read().decode("utf-8"))
        except Exception as exc:
            raise APIError(
                "No se pudo conectar con el motor de traducción. Inténtalo nuevamente."
            ) from exc
