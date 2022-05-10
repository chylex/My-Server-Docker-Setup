#!/bin/bash

source /scripts/utils.sh

sanity_var DB_TYPE "Database Type"
sanity_var DB_HOST "Database Host"
sanity_var DB_USER "Database User"
sanity_var DB_PASS "Database Password"

if [ -n "${DB_PASS}" ] && [ -z "${DB_PASS_FILE}" ]; then
    file_env 'DB_PASS'
fi

case "${DB_TYPE,,}" in
    "postgres" | "postgresql")
        DB_TYPE=postgresql
        DB_PORT="${DB_PORT:-5432}"
        export PGHOST="${DB_HOST}"
        export PGPORT="${DB_PORT}"
        export PGUSER="${DB_USER}"
        export PGPASSWORD="${DB_PASS}"
    ;;
    *)
        echo "Unknown database type: ${DB_TYPE}"
        exit 1
    ;;
esac

COUNTER=0
report_db_unavailable() {
    print_warn "Database server '${DB_HOST}' is not accessible, retrying... waited $COUNTER${1: -1} so far"
    sleep "$1"
    (( COUNTER+="${1::-1}" ))
}

check_db_availability() {
    case "${DB_TYPE}" in
        "postgresql")
            until pg_isready -q; do
                report_db_unavailable "$1"
            done
        ;;
    esac

    COUNTER=0
}
