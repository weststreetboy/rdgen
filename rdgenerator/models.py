from django.db import models

class GithubRun(models.Model):
    id = models.IntegerField(verbose_name="ID",primary_key=True)
    uuid = models.CharField(verbose_name="uuid", max_length=100)
    status = models.CharField(verbose_name="status", max_length=100)
    github_run_id = models.BigIntegerField(null=True, blank=True)
    # Carried over from the dispatch request so completion notifications can
    # deep-link straight to the download / status page.
    filename = models.CharField(verbose_name="filename", max_length=200, blank=True, default="")
    platform = models.CharField(verbose_name="platform", max_length=50, blank=True, default="")
    # Guards the one-time "build complete" notification (backend push). The
    # browser Notification in the terminal templates is independent of this.
    notified = models.BooleanField(verbose_name="notified", default=False)
