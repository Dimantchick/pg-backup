Запустите: docker-compose up -d

Для восстановления: docker exec pg-backup /app/pg_restore.sh имя_файла_в_s3.sql.gz