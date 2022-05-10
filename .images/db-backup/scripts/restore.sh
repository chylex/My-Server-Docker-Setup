#!/bin/bash
set -e

source /scripts/database.sh

RESTORE_FILENAME="$(cat /backup/restore)"
RESTORE_PATH="/backup/$RESTORE_FILENAME"

if [ ! -f "$RESTORE_PATH" ]; then
    echo "Backup file missing: $RESTORE_FILENAME"
    exit 1
fi

# Setup Decompression
COMPRESSED_EXTENSION="${RESTORE_FILENAME##*.sql}"

case "$COMPRESSED_EXTENSION" in
    ".gz")
        dumpoutput="zcat"
        echo "Decompressing backup with gzip"
    ;;
    ".zst")
        dumpoutput="zstdcat"
        echo "Decompressing backup with zstd"
    ;;
    "")
        dumpoutput="cat"
    ;;
    *)
        echo "Unknown extension: $COMPRESSED_EXTENSION"
        exit 1
    ;;
esac

# Functions
restore_postgresql() {
    echo "Restoring PostgreSQL..."

    echo "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid != pg_backend_pid() AND datname IS NOT NULL" | psql --echo-errors -d postgres >/dev/null
    $dumpoutput "$RESTORE_PATH" | psql --echo-errors -d postgres >/dev/null
    vacuumdb --all --analyze
}

# Restore Backup
check_db_availability 10s
restore_"${DB_TYPE}"

### Cleanup
rm "/backup/restore"
