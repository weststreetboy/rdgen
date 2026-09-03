FROM python:3.13-alpine

# su-exec lets the entrypoint drop from root to an unprivileged user after it
# has fixed ownership on the mounted volumes. Alpine ships no gosu by default.
RUN apk add --no-cache su-exec wget

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DJANGO_SETTINGS_MODULE=rdgen.settings

WORKDIR /opt/rdgen

# Dependencies are copied first so the layer stays cached across code changes.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Fixed uid/gid so bind-mounted host directories can be matched with a single
# `chown 1000:1000` on the host. Alpine's default user would get a random id.
RUN adduser -D -u 1000 -g 1000 user

# --chown matters: without it every file lands as root, and the unprivileged
# user could never write to exe/, png/, temp_zips/ or media/ at runtime.
COPY --chown=user:user . .

RUN mkdir -p exe png temp_zips media \
 && chown -R user:user /opt/rdgen

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8000/ || exit 1

# Entrypoint runs as root, repairs volume ownership, then drops to `user`.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["gunicorn", "-c", "gunicorn.conf.py", "rdgen.wsgi:application"]
