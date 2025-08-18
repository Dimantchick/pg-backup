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

# Проверяем существование бакета и создаем если нужно
if ! s3cmd ls "s3://${S3_BUCKET}" >/dev/null 2>&1; then
    echo "🆕 Бакет ${S3_BUCKET} не существует, создаем..."
    if ! s3cmd mb "s3://${S3_BUCKET}"; then
        echo "❌ Не удалось создать бакет ${S3_BUCKET}"
        exit 1
    fi
    echo "✅ Бакет успешно создан"
else
    echo "🔍 Бакет ${S3_BUCKET} уже существует"
fi

# Проверяем наличие переменной CRON_SCHEDULE
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"

# Настраиваем crontab
echo "$CRON_SCHEDULE /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание: $CRON_SCHEDULE"
echo "🌍 S3 регион: ${S3_REGION:-ru-central-1}"
echo "📦 Используемый бакет: ${S3_BUCKET}"

exec "$@"