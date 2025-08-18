#!/bin/bash

[ -z "${POSTGRES_PASSWORD}" ] && {
    echo "❌ Ошибка: Не задан POSTGRES_PASSWORD" >&2
    exit 1
}

export PGPASSWORD="${POSTGRES_PASSWORD}"
CONFIG_PATH="/app/.s3cfg"

if [ -z "$1" ]; then
    echo "📦 Доступные бэкапы:"
    s3cmd -c ${CONFIG_PATH} --region="${S3_REGION:-ru-central-1}" ls "s3://${S3_BUCKET}/" || {
        echo "❌ Ошибка при получении списка бэкапов" >&2
        exit 1
    }
    echo -e "\nИспользование: $0 имя_файла.sql.gz"
    exit 1
fi

FILE="$1"
TMP_FILE="/tmp/restore_${FILE}"

touch "${TMP_FILE}" && chown appuser:appuser "${TMP_FILE}" || {
    echo "❌ Нет доступа к ${TMP_FILE}" >&2
    exit 1
}

echo "🔙 [$(date)] Восстановление ${POSTGRES_DB} из ${FILE}"

s3cmd -c ${CONFIG_PATH} --region="${S3_REGION:-ru-central-1}" get "s3://${S3_BUCKET}/${FILE}" "${TMP_FILE}" || {
    echo "❌ Ошибка загрузки из S3" >&2
    rm -f "${TMP_FILE}"
    exit 1
}

{
    psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" && \
    psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE ${POSTGRES_DB};" && \
    gunzip -c "${TMP_FILE}" | psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
} || {
    echo "❌ Ошибка восстановления" >&2
    rm -f "${TMP_FILE}"
    exit 1
}

rm -f "${TMP_FILE}"
echo -e "\n✅ [$(date)] База ${POSTGRES_DB} восстановлена"
echo "📊 Размер БД: $(psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT pg_size_pretty(pg_database_size('${POSTGRES_DB}'));" -t)"
exit 0