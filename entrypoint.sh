#!/bin/sh
set -e

DATA_DIRS="/opt/rdgen/exe /opt/rdgen/png /opt/rdgen/temp_zips /opt/rdgen/media"

for d in $DATA_DIRS; do
    mkdir -p "$d"
    # Volumes bind-mounted from the host keep the host's uid. Without this the
    # unprivileged app user cannot write icon uploads or generated secrets zips.
    chown -R 1000:1000 "$d" 2>/dev/null || echo "warn: cannot chown $d (read-only mount?)" >&2
done

# db.sqlite3 comes from a bind-mounted host FILE (see docker-compose.synology.yml).
# If that host file was missing at first start, Docker silently creates a
# *directory* at the mount path, and SQLite then dies with the very cryptic
# "unable to open database file". Detect it here and say what actually broke.
if [ -d /opt/rdgen/db.sqlite3 ]; then
    echo "ERROR: /opt/rdgen/db.sqlite3 is a DIRECTORY, not a file." >&2
    echo "       A volume was mounted onto the database file path and the host" >&2
    echo "       file did not exist, so Docker created a folder instead." >&2
    echo "       Fix on the host:  touch db.sqlite3   then recreate the container." >&2
    exit 1
fi

touch /opt/rdgen/db.sqlite3 2>/dev/null || true
chown 1000:1000 /opt/rdgen/db.sqlite3 2>/dev/null || true

if [ "$1" = "gunicorn" ]; then
    echo "Applying database migrations..."
    su-exec user python manage.py migrate --noinput
fi

exec su-exec user "$@"
