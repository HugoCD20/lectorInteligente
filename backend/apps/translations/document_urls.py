from django.urls import path

from apps.translations import views

urlpatterns = [
    path(
        "<int:pk>/translate/",
        views.TranslateDocumentView.as_view(),
        name="document-translate",
    ),
    path(
        "<int:pk>/translations/",
        views.DocumentTranslationsView.as_view(),
        name="document-translations",
    ),
    path(
        "<int:pk>/translations/<str:target_language>/",
        views.TranslationDetailView.as_view(),
        name="translation-detail",
    ),
]
