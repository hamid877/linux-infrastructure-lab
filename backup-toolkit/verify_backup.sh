#!/bin/bash

BACKUP_DIR="$HOME/backup-toolkit/backups"

if [ -z "$1" ]; then
    FILE=$(ls -1t "$BACKUP_DIR"/linux-backup-*.tar.gz | head -1)
else
    FILE="$1"
fi

if [ ! -f "$FILE" ]; then
    echo "Backup archive not found."
    exit 1
fi

if [ ! -f "$FILE.sha256" ]; then
    echo "Checksum file not found: $FILE.sha256"
    exit 1
fi

sha256sum -c "$FILE.sha256"
