import os

# Host and port for Gunicorn to listen on
bind = os.environ.get("GUNICORN_BIND", "0.0.0.0:8000")

# Kept deliberately modest: RDGen writes to SQLite, and every extra worker
# process is another contender for the same write lock. 3 x 2 handles the
# traffic this tool sees (a form post plus a few Actions callbacks per build)
# while keeping memory around a third of the previous 5 x 6 setting.
workers = int(os.environ.get("GUNICORN_WORKERS", "3"))
threads = int(os.environ.get("GUNICORN_THREADS", "2"))

# Build dispatch can sit for a while before GitHub Actions reports back.
timeout = int(os.environ.get("GUNICORN_TIMEOUT", "120"))

# Path to your Django project's main WSGI application file
wsgi_app = "rdgen.wsgi:application"
