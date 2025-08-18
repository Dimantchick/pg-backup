FROM alpine:3.22

RUN apk add --no-cache \
    postgresql-client \
    s3cmd \
    bash \
    tzdata \
    busybox-extras \
    gzip \
    dcron

RUN addgroup -S appuser && adduser -S appuser -G appuser -h /app

RUN mkdir -p /app /var/log && \
    touch /var/log/cron.log && \
    chown -R appuser:appuser /app /var/log/cron.log && \
    chmod 666 /var/log/cron.log

WORKDIR /app

COPY --chown=appuser:appuser pg_backup.sh pg_restore.sh entrypoint.sh ./
RUN chmod +x pg_backup.sh pg_restore.sh entrypoint.sh

USER appuser

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["crond", "-f", "-l", "8"]