FROM alpine:3.22

RUN apk add --no-cache \
    postgresql-client \
    s3cmd \
    bash \
    tzdata \
    busybox-extras \
    gzip

WORKDIR /app

RUN echo "176.109.98.30 s3.cloud.ru" >> /etc/hosts

COPY pg_backup.sh pg_restore.sh entrypoint.sh ./
RUN chmod +x pg_backup.sh pg_restore.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["crond", "-f", "-l", "8", "-L", "/dev/stdout"]