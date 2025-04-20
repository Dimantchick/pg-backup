#!/bin/sh

# Создаем crontab
echo "0 2 * * * /app/pg_backup.sh >> /proc/1/fd/1 2>&1" > /etc/crontabs/root
echo "*/5 * * * * date >> /proc/1/fd/1" >> /etc/crontabs/root
chmod 0644 /etc/crontabs/root

echo "🟢 Контейнер инициализирован"
echo "📌 Расписание:"
cat /etc/crontabs/root

exec "$@"