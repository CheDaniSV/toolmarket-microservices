#!/bin/bash
set -e

# Настройки
source ../../.env
export PGPASSWORD="$POSTGRES_PASSWORD"

CONTAINER_NAME="db"
BACKUP_DIR="../../backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${POSTGRES_DB}_${TIMESTAMP}.dump"

# Выполняем pg_dump внутри контейнера
docker compose exec -T ${CONTAINER_NAME} pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB} -F c > ${BACKUP_FILE}

unset PGPASSWORD

# Проверяем успешность
if [ $? -eq 0 ]; then
    echo "Backup created successfully: ${BACKUP_FILE}"
    # Удаляем старые бэкапы, старше 7 дней (опционально)
    find ${BACKUP_DIR} -name "${POSTGRES_DB}_*.sql" -type f -mtime +7 -delete
else
    echo "Backup failed!"
    exit 1
fi

# docker compose exec db pg_restore -U postgres -d toolmarket -C -c < ./backups/backup.dump