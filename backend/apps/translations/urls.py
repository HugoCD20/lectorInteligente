from django.urls import path

from apps.translations import views

urlpatterns = [
    path("languages/", views.LanguagesView.as_view(), name="translation-languages"),
]
