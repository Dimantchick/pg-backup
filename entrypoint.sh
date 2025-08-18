#!/bin/sh

# Генерируем конфиг s3cmd динамически
cat > /root/.s3cfg <<EOF
[default]
access_key = ${AWS_ACCESS_KEY_ID}
secret_key = ${AWS_SECRET_ACCESS_KEY}
host_base = ${S3_ENDPOINT:-s3.cloud.ru}
host_bucket = %(bucket)s.${S3_ENDPOINT:-s3.cloud.ru}
use_https = True
EOF

# Проверяем наличие переменной CRON_SCHEDULE и используем значение по умолчанию
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"

# Создаем crontab
echo "$CRON_SCHEDULE /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание:"
cat /etc/crontabs/root
echo ""
echo "🔧 Конфигурация S3cmd:"
cat /root/.s3cfg | grep -v 'secret_key'

exec "$@"