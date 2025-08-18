#!/bin/bash

export PGPASSWORD="${POSTGRES_PASSWORD}"
CONFIG_PATH="/app/.s3cfg"
BACKUP_FILE="${POSTGRES_DB}_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"
TMP_BACKUP="/tmp/${BACKUP_FILE}"

echo "[$(date)] Создание бэкапа ${POSTGRES_DB}..."

pg_dump -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${TMP_BACKUP}" || {
    echo "❌ Ошибка создания бэкапа"
    rm -f "${TMP_BACKUP}"
    exit 1
}

s3cmd -c ${CONFIG_PATH} --region="${S3_REGION:-ru-central-1}" put "${TMP_BACKUP}" "s3://${S3_BUCKET}/" || {
    echo "❌ Ошибка загрузки в S3"
    rm -f "${TMP_BACKUP}"
    exit 1
}
rm -f "${TMP_BACKUP}"

if [ "${DAYS_TO_KEEP}" -gt 0 ]; then
    echo "🧹 Удаление старых бэкапов (>${DAYS_TO_KEEP} дней)..."
    s3cmd -c ${CONFIG_PATH} --region="${S3_REGION:-ru-central-1}" ls "s3://${S3_BUCKET}/" | while read -r line; do
        file_date=$(echo "${line}" | awk '{print $1" "$2}')
        file_name=$(echo "${line}" | awk '{print $4}' | sed "s|s3://${S3_BUCKET}/||")

        if [[ "${file_name}" =~ ^${POSTGRES_DB}_[0-9]{4}-[0-9]{2}-[0-9]{2}.*\.sql\.gz$ ]]; then
            file_epoch=$(date -d "${file_date}" +%s 2>/dev/null || echo 0)
            age_days=$(( ($(date +%s) - file_epoch) / 86400 ))

            if [ "${age_days}" -gt "${DAYS_TO_KEEP}" ]; then
                echo "🗑️ Удаляем: ${file_name} (${age_days} дней)"
                s3cmd -c ${CONFIG_PATH} --region="${S3_REGION:-ru-central-1}" del "s3://${S3_BUCKET}/${file_name}" || \
                echo "⚠️ Не удалось удалить ${file_name}"
            fi
        fi
    done
fi

echo "✅ [$(date)] Бэкап успешно создан: s3://${S3_BUCKET}/${BACKUP_FILE}"
exit 0