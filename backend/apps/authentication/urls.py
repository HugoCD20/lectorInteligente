from django.urls import path

from apps.authentication import views

urlpatterns = [
    path("register/", views.RegisterView.as_view(), name="register"),
    path("login/", views.LoginView.as_view(), name="login"),
    path("logout/", views.LogoutView.as_view(), name="logout"),
    path("password-reset/", views.PasswordResetRequestView.as_view(), name="password-reset"),
    path(
        "password-reset/confirm/",
        views.PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),
]
