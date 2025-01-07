#!/bin/bash
set -e

DATESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
VS_PID=$(supervisorctl pid vintagestory)

# Issue backup command to stdin of VS pid
echo "/genbackup backup_${DATESTAMP}.vcdbs" > /proc/${VS_PID}/fd/0

# Wait for our file to exist
while [ ! -f "${VINTAGE_STORY_PATH}/data/Backups/backup_${DATESTAMP}.vcdbs" ]; do
    echo "Waiting for backup to be created"
    sleep 2
done

# Make sure writing of file is complete
while lsof "${VINTAGE_STORY_PATH}/data/Backups/backup_${DATESTAMP}.vcdbs" > /dev/null; do
    echo "Waiting for backup to be finalized"
    sleep 2
done

# Compress the backup to save some space
echo "Compressing backup"
tar czf ${VINTAGE_STORY_PATH}/data/Backups/server_backup_${DATESTAMP}.tar.gz -C ${VINTAGE_STORY_PATH}/data/Backups/backup_${DATESTAMP}.vcdbs

echo "Backup server_backup_${DATESTAMP}.tar.gz created"

# Clean up original
rm -f ${VINTAGE_STORY_PATH}/data/Backups/backup_${DATESTAMP}.vcdbs

# Remove older backups
if [[ -z "${BACKUP_RETENTION_MINUTES}" ]]; then
    echo "Cleaning up previous backups older than ${BACKUP_RETENTION_DAYS} days"
    find "${VINTAGE_STORY_PATH}/data/Backups" -name "server_backup_*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -exec rm -f {} \;
else
    echo "Cleaning up previous backups older than ${BACKUP_RETENTION_MINUTES} minutes"
    find "${VINTAGE_STORY_PATH}/data/Backups" -name "server_backup_*.tar.gz" -type f -mmin +${BACKUP_RETENTION_MINUTES} -exec rm -f {} \;
fi
