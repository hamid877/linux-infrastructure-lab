#!/bin/bash

# =========================================
# Linux Infrastructure Lab - Backup Cleanup
# Version 1.0
# =========================================

BACKUP_DIR="$HOME/linux-lab/backup-toolkit/backups"
KEEP=7

echo "========================================="
echo "      BACKUP RETENTION POLICY"
echo "========================================="
echo

TOTAL=$(ls -1 "$BACKUP_DIR"/linux-backup-*.tar.gz 2>/dev/null | wc -l)

echo "Total backups found : $TOTAL"
echo "Backups to keep     : $KEEP"
echo

if [ "$TOTAL" -le "$KEEP" ]; then
    echo "Nothing to clean. Backup count is within the retention limit."
    exit 0
fi

echo "Removing old backups..."

ls -1t "$BACKUP_DIR"/linux-backup-*.tar.gz |
tail -n +$((KEEP + 1)) |
while read FILE; do

    echo "Deleting $(basename "$FILE")"

    rm -f "$FILE"
    rm -f "$FILE.sha256"

done

echo
echo "Cleanup complete."

echo
echo "Remaining backups:"
ls -lh "$BACKUP_DIR"
