#!/bin/sh

# Проверяем наличие переменной CRON_SCHEDULE и используем значение по умолчанию
CRON_SCHEDULE="${CRON_SCHEDULE:-0 2 * * *}"

# Создаем crontab
echo "$CRON_SCHEDULE /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание:"
cat /etc/crontabs/root

exec "$@"