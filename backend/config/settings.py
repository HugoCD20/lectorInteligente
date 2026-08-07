import sys
from datetime import timedelta
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(list, []),
    DJANGO_CORS_ORIGINS=(list, []),
    POSTGRES_DB=(str, "lector_inteligente"),
    POSTGRES_USER=(str, "lector"),
    POSTGRES_PASSWORD=(str, ""),
    POSTGRES_HOST=(str, "localhost"),
    POSTGRES_PORT=(int, 5432),
    LIBRETRANSLATE_URL=(str, "http://libretranslate:5000"),
    API_PAGE_SIZE=(int, 10),
    MAX_DOCUMENT_SIZE=(int, 50 * 1024 * 1024),
    ALLOWED_DOCUMENT_EXTENSIONS=(list, ["pdf", "epub"]),
    DJANGO_EMAIL_BACKEND=(str, "django.core.mail.backends.console.EmailBackend"),
    DJANGO_EMAIL_HOST=(str, "localhost"),
    DJANGO_EMAIL_PORT=(int, 25),
    DJANGO_EMAIL_HOST_USER=(str, ""),
    DJANGO_EMAIL_HOST_PASSWORD=(str, ""),
    DJANGO_EMAIL_USE_TLS=(bool, False),
    DJANGO_EMAIL_DEFAULT_FROM=(str, "no-reply@lectorinteligente.local"),
    FRONTEND_URL=(str, "http://localhost:8080"),
    CACHE_URL=(str, ""),
    THROTTLE_ANON_RATE=(str, "100/min"),
    THROTTLE_USER_RATE=(str, "1000/day"),
    THROTTLE_AUTH_RATE=(str, "30/min"),
    THROTTLE_TRANSLATE_RATE=(str, "60/hour"),
)

env_file = BASE_DIR / ".env"
if env_file.exists():
    environ.Env.read_env(str(env_file))

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DJANGO_DEBUG")
ALLOWED_HOSTS = env("DJANGO_ALLOWED_HOSTS")

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "corsheaders",
    "rest_framework_simplejwt.token_blacklist",
]

POSTGRES_APPS = [
    "django.contrib.postgres",
]

LOCAL_APPS = [
    "apps.common",
    "apps.core",
    "apps.users",
    "apps.authentication",
    "apps.documents",
    "apps.translations",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + POSTGRES_APPS + LOCAL_APPS

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.gzip.GZipMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.common.middleware.LoggingMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": env("POSTGRES_DB"),
        "USER": env("POSTGRES_USER"),
        "PASSWORD": env("POSTGRES_PASSWORD"),
        "HOST": env("POSTGRES_HOST"),
        "PORT": env("POSTGRES_PORT"),
    }
}

AUTH_USER_MODEL = "users.User"

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

LANGUAGE_CODE = "es"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "static"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

THROTTLE_RATES = {
    "anon": env("THROTTLE_ANON_RATE"),
    "user": env("THROTTLE_USER_RATE"),
    "auth": env("THROTTLE_AUTH_RATE"),
    "translate": env("THROTTLE_TRANSLATE_RATE"),
}

DEFAULT_RENDERER_CLASSES = [
    "rest_framework.renderers.JSONRenderer",
]
if DEBUG:
    DEFAULT_RENDERER_CLASSES.append("rest_framework.renderers.BrowsableAPIRenderer")

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_THROTTLE_CLASSES": (
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ),
    "DEFAULT_THROTTLE_RATES": THROTTLE_RATES,
    "DEFAULT_RENDERER_CLASSES": DEFAULT_RENDERER_CLASSES,
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": env("API_PAGE_SIZE"),
    "EXCEPTION_HANDLER": "apps.common.exception_handler.custom_exception_handler",
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "UPDATE_LAST_LOGIN": True,
}

CORS_ALLOWED_ORIGINS = env("DJANGO_CORS_ORIGINS")

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[{asctime}] {levelname} {name} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": str(BASE_DIR / "logs" / "app.log"),
            "maxBytes": 5 * 1024 * 1024,
            "backupCount": 5,
            "formatter": "verbose",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
        },
        "apps": {
            "handlers": ["console", "file"],
            "level": "DEBUG",
        },
    },
}

LIBRETRANSLATE_URL = env("LIBRETRANSLATE_URL")

MAX_DOCUMENT_SIZE = env("MAX_DOCUMENT_SIZE")
ALLOWED_DOCUMENT_EXTENSIONS = env("ALLOWED_DOCUMENT_EXTENSIONS")

EMAIL_BACKEND = env("DJANGO_EMAIL_BACKEND")
EMAIL_HOST = env("DJANGO_EMAIL_HOST")
EMAIL_PORT = env("DJANGO_EMAIL_PORT")
EMAIL_HOST_USER = env("DJANGO_EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = env("DJANGO_EMAIL_HOST_PASSWORD")
EMAIL_USE_TLS = env("DJANGO_EMAIL_USE_TLS")
DEFAULT_FROM_EMAIL = env("DJANGO_EMAIL_DEFAULT_FROM")

FRONTEND_URL = env("DJANGO_FRONTEND_URL")

CACHE_URL = env("CACHE_URL")
if CACHE_URL:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.redis.RedisCache",
            "LOCATION": CACHE_URL,
            "KEY_PREFIX": "lector_inteligente",
            "TIMEOUT": 300,
        }
    }
else:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "KEY_PREFIX": "lector_inteligente",
            "TIMEOUT": 300,
        }
    }
