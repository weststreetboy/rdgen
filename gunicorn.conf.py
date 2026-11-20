# Gunicorn configuration for rdgen
import os

# Host and port for Gunicorn to listen on. GUNICORN_BIND is honoured so the
# app can be launched on WorkBuddy's injected port; default matches upstream.
bind = os.environ.get("GUNICORN_BIND", "0.0.0.0:8000")

# Workers/threads kept modest on the fork: RDGen writes to SQLite, and each
# extra worker contends for the same write lock. A 3x2 pool handles the form
# posts plus Actions callbacks this tool sees. Override via env if needed.
workers = int(os.environ.get("GUNICORN_WORKERS", "3"))
threads = int(os.environ.get("GUNICORN_THREADS", "2"))

# Build dispatch can sit a while before GitHub reports back.
timeout = int(os.environ.get("GUNICORN_TIMEOUT", "120"))

# Reliability settings adopted from upstream.
graceful_timeout = 30
max_requests = 1000
max_requests_jitter = 50
preload_app = True
activate_base = True

# Path to your Django project's main WSGI application file
wsgi_app = "rdgen.wsgi:application"

# LOG_FORMAT=json: emit one JSON object per line (upstream JSON logging).
if os.environ.get("LOG_FORMAT", "").lower() == "json":
    logconfig_dict = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {"json": {"()": "rdgen.jsonlog.JSONFormatter"}},
        "handlers": {
            "console": {
                "class": "logging.StreamHandler",
                "formatter": "json",
                "stream": "ext://sys.stdout",
            },
        },
        "loggers": {
            "gunicorn.error": {"handlers": ["console"], "level": "INFO", "propagate": False},
            "gunicorn.access": {"handlers": [], "propagate": False},
        },
    }
