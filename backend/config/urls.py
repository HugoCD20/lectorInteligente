from django.contrib import admin
from django.urls import include, path

from apps.common.jwt_views import (
    CustomTokenObtainPairView,
    CustomTokenRefreshView,
    CustomTokenVerifyView,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("apps.core.urls")),
    path("api/auth/", include("apps.authentication.urls")),
    path("api/users/", include("apps.users.urls")),
    path("api/documents/", include("apps.translations.document_urls")),
    path("api/documents/", include("apps.documents.urls")),
    path("api/translation/", include("apps.translations.urls")),
    path("api/auth/token/", CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", CustomTokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/token/verify/", CustomTokenVerifyView.as_view(), name="token_verify"),
]
