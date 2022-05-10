#!/bin/bash
set -e

if [ -f "/backup/restore" ]; then
    echo "A backup restore file is present, it is not safe to resume the backup schedule. Waiting for the file to be removed..."
    while [ -f "/backup/restore" ]; do
        sleep 5s
    done
fi

echo "${CRON:-"0 */2 * * *"} /bin/bash /scripts/backup.sh" > /crontab
/bin/supercronic /crontab
