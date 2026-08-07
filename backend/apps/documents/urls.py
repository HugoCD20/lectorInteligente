from django.urls import path

from apps.documents import views

urlpatterns = [
    path("", views.GalleryView.as_view(), name="documents-gallery"),
    path("upload/", views.DocumentUploadView.as_view(), name="document-upload"),
    path("recent/", views.RecentDocumentsView.as_view(), name="documents-recent"),
    path("<int:pk>/read/", views.DocumentReadView.as_view(), name="document-read"),
    path("<int:pk>/file/", views.DocumentFileView.as_view(), name="document-file"),
    path("<int:pk>/", views.DocumentDetailView.as_view(), name="document-detail"),
]
