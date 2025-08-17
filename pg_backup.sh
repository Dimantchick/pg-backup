#!/bin/bash

# Проверка обязательных переменных
required_vars=("POSTGRES_PASSWORD" "POSTGRES_HOST" "POSTGRES_USER" "POSTGRES_DB"
               "S3_BUCKET" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Ошибка: Не задана переменная $var" >&2
        exit 1
    fi
done

export PGPASSWORD="${POSTGRES_PASSWORD}"
TMP_BACKUP="/tmp/${POSTGRES_DB}_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

echo "[$(date)] Создание бэкапа ${POSTGRES_DB}..."

# Создаем бэкап
pg_dump -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${TMP_BACKUP}" || {
    echo "❌ Ошибка создания бэкапа!"
    rm -f "${TMP_BACKUP}"
    exit 1
}

# Загружаем в S3
echo "Загрузка в S3..."
mcli cp "${TMP_BACKUP}" "s3/${S3_BUCKET}/" || {
    echo "❌ Ошибка загрузки в S3!"
    echo "Проверьте:"
    echo "1. Доступность S3 эндпоинта"
    echo "2. Корректность ключей доступа"
    echo "3. Наличие прав на запись в бакет"
    rm -f "${TMP_BACKUP}"
    exit 1
}
rm -f "${TMP_BACKUP}"

# Очистка старых бэкапов
if [ -n "${DAYS_TO_KEEP}" ] && [ "${DAYS_TO_KEEP}" -gt 0 ]; then
    echo "Удаление бэкапов старше ${DAYS_TO_KEEP} дней..."
    mcli ls "s3/${S3_BUCKET}/" | grep -E "${POSTGRES_DB}_[0-9]{4}-[0-9]{2}-[0-9]{2}.*\.sql\.gz$" | \
    while read -r line; do
        file_date=$(echo "${line}" | awk '{print $1" "$2" "$3" "$4" "$5" "$6}')
        file_name=$(echo "${line}" | awk '{print $NF}')

        file_epoch=$(date -d "${file_date}" +%s 2>/dev/null || echo 0)
        current_epoch=$(date +%s)

        if [ "${file_epoch}" -gt 0 ]; then
            age_days=$(( (current_epoch - file_epoch) / 86400 ))

            if [ "${age_days}" -gt "${DAYS_TO_KEEP}" ]; then
                echo "Удаляем: ${file_name} (${age_days} дней)"
                if ! mcli rm "s3/${S3_BUCKET}/${file_name}"; then
                    echo "⚠️ Предупреждение: не удалось удалить ${file_name}"
                fi
            fi
        else
            echo "⚠️ Не удалось определить дату файла: ${file_name}"
        fi
    done
fi

echo "✅ [$(date)] Бэкап завершен. Файл: s3/${S3_BUCKET}/$(basename ${TMP_BACKUP})"
exit 0