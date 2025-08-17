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

if [ -z "$1" ]; then
    echo "Доступные бэкапы:"
    mcli ls "s3/${S3_BUCKET}/" | grep -E "${POSTGRES_DB}_[0-9]{4}-[0-9]{2}-[0-9]{2}.*\.sql\.gz$" || {
        echo "❌ Ошибка при получении списка бэкапов" >&2
        exit 1
    }
    echo ""
    echo "Использование: $0 имя_файла.sql.gz"
    exit 1
fi

FILE="$1"
TMP_FILE="/tmp/restore_${FILE}"

echo "[$(date)] Начало восстановления базы ${POSTGRES_DB} из файла ${FILE}..."

# Загрузка файла из S3
echo "1. Загрузка файла из S3..."
mcli cp "s3/${S3_BUCKET}/${FILE}" "${TMP_FILE}" || {
    echo "❌ Ошибка: Не удалось загрузить файл ${FILE} из S3" >&2
    exit 1
}

# Очистка базы перед восстановлением
echo "2. Очистка базы данных..."
psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" || {
    echo "❌ Ошибка: Не удалось удалить базу данных ${POSTGRES_DB}" >&2
    rm -f "${TMP_FILE}"
    exit 1
}

psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE ${POSTGRES_DB};" || {
    echo "❌ Ошибка: Не удалось создать базу данных ${POSTGRES_DB}" >&2
    rm -f "${TMP_FILE}"
    exit 1
}

# Восстановление данных
echo "3. Восстановление данных..."
gunzip -c "${TMP_FILE}" | psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" || {
    echo "❌ Ошибка: Не удалось восстановить данные" >&2
    echo "Проверьте:" >&2
    echo "1. Соответствие структуры бэкапа текущей БД" >&2
    echo "2. Права пользователя ${POSTGRES_USER}" >&2
    rm -f "${TMP_FILE}"
    exit 1
}

# Очистка временного файла
rm -f "${TMP_FILE}"
echo ""
echo "✅ [$(date)] Успешно восстановлена база ${POSTGRES_DB} из файла ${FILE}"
echo "📊 Размер восстановленной БД: $(psql -h "${POSTGRES_HOST}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT pg_size_pretty(pg_database_size('${POSTGRES_DB}'));" -t)"
exit 0