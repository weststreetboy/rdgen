# Generated for RDGen build-completion notification support.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rdgenerator', '0002_githubrun_github_run_id'),
    ]

    operations = [
        migrations.AddField(
            model_name='githubrun',
            name='filename',
            field=models.CharField(blank=True, default='', max_length=200, verbose_name='filename'),
        ),
        migrations.AddField(
            model_name='githubrun',
            name='platform',
            field=models.CharField(blank=True, default='', max_length=50, verbose_name='platform'),
        ),
        migrations.AddField(
            model_name='githubrun',
            name='notified',
            field=models.BooleanField(default=False, verbose_name='notified'),
        ),
    ]
