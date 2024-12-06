#!/bin/bash
# Backup datestamp variable
DATESTAMP=$(date +\%Y\%m\%d)

# Stop Vintage Story
echo "Stopping Vintage Story server process to perform backup"
supervisorctl stop vintagestory
sleep 15

# Perform backup
tar --exclude='./Backups' --exclude='./BackupSaves' -czf ${VINTAGE_STORY_PATH}/data/Backups/server_backup_${DATESTAMP}.tar.gz -C ${VINTAGE_STORY_PATH}/data .
echo "Backup created at ${VINTAGE_STORY_PATH}/data/Backups/server_backup_${DATESTAMP}.tar.gz"

# Cleanup old backups
echo "Cleaning up previous backups older than ${BACKUP_RETENTION_DAYS} days"
find ${VINTAGE_STORY_PATH}/data/Backups -name "server_backup_*.tar.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -exec rm -f {} \;

# Start Vintage Story
echo "Backup process complete, starting Vintage Story server process"
sleep 15
supervisorctl start vintagestory
