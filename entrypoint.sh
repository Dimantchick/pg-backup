#!/bin/sh

# Генерируем конфиг s3cmd динамически
cat > /root/.s3cfg <<EOF
[default]
access_key = ${AWS_ACCESS_KEY_ID}
secret_key = ${AWS_SECRET_ACCESS_KEY}
host_base = ${S3_ENDPOINT:-s3.cloud.ru}
host_bucket = %(bucket)s.${S3_ENDPOINT:-s3.cloud.ru}
use_https = True
bucket_location = ${S3_REGION:-ru-central-1}
human_readable_sizes = True
EOF

# Проверяем наличие переменной CRON_SCHEDULE
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"

# Настраиваем crontab
echo "$CRON_SCHEDULE /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание: $CRON_SCHEDULE"
echo "🌍 S3 регион: ${S3_REGION:-ru-central-1}"

exec "$@"