#!/bin/bash

# =========================================
# Linux Infrastructure Lab - Restore Toolkit
# Version 1.0
# =========================================

BACKUP_DIR="$HOME/linux-lab/backup-toolkit/backups"
RESTORE_DIR="$HOME/linux-lab/backup-toolkit/restore"

# Use latest backup if no archive is provided
if [ -z "$1" ]; then
    ARCHIVE=$(ls -1t "$BACKUP_DIR"/linux-backup-*.tar.gz 2>/dev/null | head -1)
else
    ARCHIVE="$1"
fi

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
    echo "Backup archive not found."
    exit 1
fi

if [ ! -f "$ARCHIVE.sha256" ]; then
    echo "Checksum file missing: $ARCHIVE.sha256"
    exit 1
fi

echo "========================================="
echo "      BACKUP RESTORE TOOLKIT"
echo "========================================="
echo

echo "Using archive:"
echo "$ARCHIVE"
echo

echo "Verifying backup integrity..."
if ! sha256sum -c "$ARCHIVE.sha256"; then
    echo "Backup verification FAILED."
    exit 1
fi

echo "Integrity verified."
echo

mkdir -p "$RESTORE_DIR"

echo "Cleaning previous restore directory..."
rm -rf "$RESTORE_DIR"/*

echo "Extracting archive..."
tar -xzf "$ARCHIVE" -C "$RESTORE_DIR"

echo
echo "Restore completed successfully."
echo "Files restored to:"
echo "$RESTORE_DIR"

echo
echo "Restored contents:"
tree "$RESTORE_DIR" -L 2
