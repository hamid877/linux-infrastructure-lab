#!/bin/bash

TIMESTAMP=$(date +%F-%H%M%S)

BACKUP_ROOT="$HOME/backup-toolkit/backups"
TEMP_DIR="$HOME/backup-toolkit/tmp/$TIMESTAMP"

mkdir -p "$BACKUP_ROOT"
mkdir -p "$TEMP_DIR"

echo "Creating temporary backup workspace..."

rsync -a "$HOME/linux-lab/scripts/" "$TEMP_DIR/scripts"
rsync -a "$HOME/linux-lab/incident-toolkit/" "$TEMP_DIR/incident-toolkit"
sudo rsync -a /etc/nginx "$TEMP_DIR/"

ARCHIVE="$BACKUP_ROOT/linux-backup-$TIMESTAMP.tar.gz"

echo "Creating archive..."

tar -czf "$ARCHIVE" -C "$TEMP_DIR" .

echo "Generating checksum..."

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

rm -rf "$TEMP_DIR"

echo
echo "Backup completed successfully."
echo "Archive  : $ARCHIVE"
echo "Checksum : $ARCHIVE.sha256"
