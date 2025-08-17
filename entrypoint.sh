#!/bin/sh

# Настройка MinIO Client (mcli)
if [ -n "${S3_ENDPOINT}" ] && [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
    mkdir -p ~/.mcli
    cat > ~/.mcli/config.json <<EOF
{
  "version": "10",
  "aliases": {
    "mys3": {
      "url": "${S3_ENDPOINT}",
      "accessKey": "${AWS_ACCESS_KEY_ID}",
      "secretKey": "${AWS_SECRET_ACCESS_KEY}",
      "api": "s3v4",
      "path": "auto"
    }
  }
}
EOF
    echo "✅ MinIO Client настроен для ${S3_ENDPOINT}"
else
    echo "⚠️  Переменные S3 не заданы, MinIO Client не настроен"
fi

# Настройка cron
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"
echo "$CRON_SCHEDULE /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание:"
cat /etc/crontabs/root

exec "$@"