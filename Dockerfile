FROM alpine:3.18

RUN apk add --no-cache \
    postgresql-client \
    minio-client \
    bash \
    tzdata \
    busybox-extras

WORKDIR /app

COPY pg_backup.sh pg_restore.sh entrypoint.sh ./
RUN chmod +x *.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["crond", "-f", "-l", "8", "-L", "/dev/stdout"]