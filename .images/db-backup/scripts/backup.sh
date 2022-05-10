#!/bin/bash
set -e

source /scripts/database.sh

backupdir=/backup
tmpdir=/tmp/backups

COMPRESSION=${COMPRESSION:-ZSTD}
BACKUP_RETENTION_MINUTES=${BACKUP_RETENTION_MINUTES:-1440}

target="$(date +%Y%m%d-%H%M%S).sql"

### Functions
backup_postgresql() {
    pg_dumpall --clean --if-exists --quote-all-identifiers | $dumpoutput > "$tmpdir/$target"
}

compression() {
    case "${COMPRESSION,,}" in
        "gzip")
            target="$target.gz"
            level="${COMPRESSION_LEVEL:-"9"}"
            dumpoutput="gzip -$level "
            print_notice "Compressing backup with gzip (level $level)"
        ;;
        "zstd")
            target="$target.zst"
            level="${COMPRESSION_LEVEL:-"10"}"
            dumpoutput="zstd --rm -$level --long=24 "
            print_notice "Compressing backup with zstd (level $level)"
        ;;
        "none")
            dumpoutput="cat "
        ;;
    esac
}

move_backup() {
    SIZE_BYTES=$(stat -c%s "$tmpdir/$target")
    SIZE_HUMAN=$(du -h "$tmpdir/$target" | awk '{ print $1 }')
    print_notice "Backup ${target} created with the size of ${SIZE_BYTES} bytes (${SIZE_HUMAN})"

    mkdir -p "$backupdir"
    mv "$tmpdir/$target" "$backupdir/$target"
}

### Commence Backup
mkdir -p "$tmpdir"
print_notice "Starting backup at $(date)"

### Take a Dump
check_db_availability 1m

compression
backup_"${DB_TYPE}"
move_backup

### Automatic Cleanup
if [[ -n "$BACKUP_RETENTION_MINUTES" ]]; then
    print_notice "Cleaning up old backups"
    find "$backupdir"/ -mmin +"${BACKUP_RETENTION_MINUTES}" -iname "*" -exec rm {} \;
fi
