FROM alpine:latest

RUN apk add --no-cache \
    postgresql-client \
    s3cmd \
    bash \
    tzdata \
    busybox-extras \
    gzip

WORKDIR /app

COPY pg_backup.sh pg_restore.sh entrypoint.sh ./
RUN chmod +x pg_backup.sh pg_restore.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["crond", "-f", "-l", "8", "-L", "/dev/stdout"]