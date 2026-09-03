#!/bin/sh
set -e

DATA_DIRS="/opt/rdgen/exe /opt/rdgen/png /opt/rdgen/temp_zips /opt/rdgen/media"

for d in $DATA_DIRS; do
    mkdir -p "$d"
    # Volumes bind-mounted from the host keep the host's uid. Without this the
    # unprivileged app user cannot write icon uploads or generated secrets zips.
    chown -R 1000:1000 "$d" 2>/dev/null || echo "warn: cannot chown $d (read-only mount?)" >&2
done

# db.sqlite3 either comes from the image or from a host volume.
touch /opt/rdgen/db.sqlite3 2>/dev/null || true
chown 1000:1000 /opt/rdgen/db.sqlite3 2>/dev/null || true

if [ "$1" = "gunicorn" ]; then
    echo "Applying database migrations..."
    su-exec user python manage.py migrate --noinput
fi

exec su-exec user "$@"
