#!/bin/sh

# Настройка s3cmd
CONFIG_PATH="/app/.s3cfg"
cat > ${CONFIG_PATH} <<EOF
[default]
access_key = ${AWS_ACCESS_KEY_ID}
secret_key = ${AWS_SECRET_ACCESS_KEY}
host_base = ${S3_ENDPOINT:-s3.cloud.ru}
host_bucket = %(bucket)s.${S3_ENDPOINT:-s3.cloud.ru}
use_https = True
bucket_location = ${S3_REGION:-ru-central-1}
human_readable_sizes = True
EOF

# Проверка бакета
if ! s3cmd -c ${CONFIG_PATH} ls "s3://${S3_BUCKET}" >/dev/null 2>&1; then
    echo "🆕 Создаем бакет ${S3_BUCKET}..."
    if ! s3cmd -c ${CONFIG_PATH} mb "s3://${S3_BUCKET}"; then
        echo "❌ Ошибка создания бакета"
        exit 1
    fi
    echo "✅ Бакет создан"
else
    echo "🔍 Бакет ${S3_BUCKET} существует"
fi

# Настройка cron
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"
CRON_LOG="/var/log/cron.log"

echo "$CRON_SCHEDULE /app/pg_backup.sh >> ${CRON_LOG} 2>&1" > /app/crontab
echo "*/5 * * * * date >> ${CRON_LOG}" >> /app/crontab
crontab /app/crontab

echo "🟢 Контейнер инициализирован"
echo "👤 Пользователь: $(whoami)"
echo "📌 Расписание: $CRON_SCHEDULE"
echo "📝 Логи cron: ${CRON_LOG}"
echo "🌍 S3 регион: ${S3_REGION:-ru-central-1}"
echo "📦 Бакет: ${S3_BUCKET}"

# Запуск cron в foreground
exec crond -f -l 8