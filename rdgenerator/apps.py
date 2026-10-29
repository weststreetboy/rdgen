from django.apps import AppConfig


class RdgeneratorConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'rdgenerator'

    def ready(self):
        # Start the build-completion notification scheduler only when a backend
        # push channel is configured. The in-browser Notification covers the
        # tab-open case without any threads, so we avoid spawning one by default.
        import os
        if os.environ.get("NOTIFY_METHOD"):
            from .views import _notify_scheduler_loop
            import threading
            t = threading.Thread(target=_notify_scheduler_loop, daemon=True)
            t.start()
