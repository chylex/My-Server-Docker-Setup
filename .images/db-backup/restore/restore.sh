#!/bin/bash
set -e

function restore() {
    BACKUP_FOLDER="/srv/$1/postgres.backup"
    RESTORE_FILE="$BACKUP_FOLDER/restore"

    cd "/app/$1"

    if ! docker compose ps --services | grep -q postgres; then
        echo "The PostgreSQL container is not running!"
        echo "You can start it using:"
        echo "  docker compose up -d postgres"
        exit 1
    fi

    if [ ! -d "$BACKUP_FOLDER" ]; then
        echo "The backup folder is missing: $BACKUP_FOLDER"
        exit 1
    fi

    readarray -t BACKUP_FILES < <(find "$BACKUP_FOLDER"/ -mindepth 1 -type f -name '*.sql*' -printf '%P\n' | sort --reverse --field-separator=_ --key=2,2)

    if [[ ${#BACKUP_FILES[@]} == 0 ]]; then
        echo "The backup folder contains no backups: $BACKUP_FOLDER"
        exit 1
    fi

    for ((i = 0; i < ${#BACKUP_FILES[@]}; i++)); do
        path="$BACKUP_FOLDER/${BACKUP_FILES[$i]}"
        item="$((i + 1))) ${BACKUP_FILES[$i]}"

        echo -n "$item  "
        printf "%$((28-${#item}))s" " "
        echo -n "|  "
        du -h "$path" | awk '{ print $1 }'
    done

    filename=""
    read -rp "Select file to restore: " option

    if [[ "$option" =~ ^[1-9][0-9]*$ ]]; then
        filename=${BACKUP_FILES[$option-1]}
    fi

    if [ -z "$filename" ]; then
        echo "Invalid option, exiting..."
        exit 1
    fi

    if docker compose ps --services --status running | grep -q -x "backup"; then
        docker compose stop backup
    fi

    if docker compose ps --services --status running | grep -q -x "$2"; then
        docker compose stop "$2"
        trap 'echo "Restarting server container..." && docker compose up -d "'"$2"'"' EXIT
    fi

    echo "Marking file for restoration: $filename"

    echo "$filename" > "$RESTORE_FILE"
    chmod 600 "$RESTORE_FILE"
    chown "app_$1_db:app_$1_db" "$RESTORE_FILE"

    echo "Starting backup restoration..."
    docker compose run --rm --entrypoint=/scripts/restore.sh backup

    echo "Starting backup container to resume scheduled backups..."
    docker compose up -d backup

    echo "Backup restored!"
}
