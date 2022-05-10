This image contains scripts that periodically backup an SQL database server (currently only PostgreSQL is supported). It is a heavily modified version of [tiredofit/docker-db-backup](https://github.com/tiredofit/docker-db-backup), with these improvements and changes:

- Ability to run as a non-root user
- Scheduling based on `cron` (via [supercronic](https://github.com/aptible/supercronic))
- Fully automated [backup restoration](#restoring-a-backup)
- Removal of features not necessary for this server

# Environment Variables

- `DB_TYPE` is the type of database server.
  - Allowed: `postgres`
- `DB_HOST` is the hostname of the database server. The hostname is the name of the service container in `docker-compose.yml`.
  - Example: `postgres`
- `DB_PORT` is the port of the database server.
  - Default: `5432` for `postgres`
- `DB_USER` is the database user that has permissions to create or restore the backup.
- `DB_PASS` is the database user's password.
- `COMPRESSION` sets the compression algorithm for backup files.
  - Default: `zstd`
  - Allowed: `none`, `gzip`, `zstd`
- `COMPRESSION_LEVEL` is the level or strength of compression. Higher levels take longer but usually result in smaller files.
  - Default: `9` when using `gzip`
  - Default: `10` when using `zstd`
  - Allowed: `1` to `9` when using `gzip`
  - Allowed: `1` to `19` when using `zstd`
- `BACKUP_RETENTION_SECONDS` is the amount of seconds backups should be kept for. Older backups are deleted when a new backup is created.
  - Default: `1440` (24 hours)
  - Example: `10080` (7 days)
  - Example: `43200` (30 days)
  - Example: `525600` (365 days)
  - Example: `""` (disables automatic cleanup)
- `CRON` is the cron expression which determines how often backups are made. The format is based on [cronexpr](https://github.com/aptible/supercronic/tree/master/cronexpr).
  - Default: `0 */2 * * *` (every 2 hours)
  - Example: `0 */4 * * *` (every 4 hours)
  - Example: `0 * * * *` (every hour)
  - Example: `0 0 * * *` (every day at midnight)
- `TZ` is the server's timezone.
  - Default: `UTC`
  - Example: `Europe/Prague`

# Locations

Database files and backups are stored in folders that follow this pattern:

- `/srv/<service>/postgres` for the database files
- `/srv/<service>/postgres.backup` for the backups

# Retention

By default, backups are made every two hours, and are **only kept for one day**.

The rationale behind these defaults is that I expect you to have daily backups of your whole server. With daily server backups, there is no need for these database backups to be stored for more than a day, since backups older than a day can be restored from your daily backups.

You can change both the frequency and retention of backups using environment variables.

# Compression

The default compression settings use `zstd` with a compression level 10, and a 24-bit (`16 MiB`) sliding window (the sliding window is hardcoded in the scripts). I found this to be a good balance of speed, size, and memory usage.

You can experiment with different settings, but keep in mind that increasing either compression level or the sliding window size will increase memory requirements. All services that use this image have a hard limit of `128 MB` RAM for the backup container, which is already very close to the actual amount this image uses with default compression settings.

# Server Downtime

If the database server is not available, the backup script will wait for a minute and then check the server's availability again. If the server is unavailable after the next scheduled backup was supposed to start, the scheduler ([supercronic](https://github.com/aptible/supercronic)) detects that the previous backup has not finished yet, and it will keep postponing the next backup until the previous one finishes.

# Restoring a Backup

Every service folder that uses this image includes a `restorebackup.sh` script. To restore the backup, `cd` into the service folder and run `./restorebackup.sh` as `root`.

The script will show you a numbered list of available backups (see [Locations](#locations)), and ask you which backup you want to restore. Type the number next to the file name and press `Enter` to proceed with the restoration, or press `Ctrl + C` to exit the script.

You may see the following two errors during the restoration, which is expected:

- `ERROR: current user cannot be dropped`
- `ERROR: role "<role>" already exists`

The restoration process should finish automatically. In case something goes wrong, here is a step-by-step description to help you troubleshoot:

1. The script checks whether the database container is running.
   - If the database container is not running, the script shows how to start the database container, and exits. This gives you a chance to ensure the database container is working.
   - If the database container isn't working, you can try wiping the folder with the actual database files (see [Locations](#locations)), and starting the database container again to create a fresh database.
2. If the backup container is still running, it is stopped.
3. If the service's server container is running, it is stopped and will be restarted when the script exits (whether it finishes successfully or not).
4. In the folder where backups are stored (see [Locations](#locations)), a file named `restore` is created. The file contains the name of the selected backup.
5. The backup container is started. It finds the `restore` file, and initiates restoration.
   - All active connections to the database server are terminated (PostgreSQL does not allow deleting databases with active connections).
   - The SQL statements in the backup file are executed.
   - The restored databases are vacuumed and analyzed.
6. If the restoration succeeded, the `restore` file is deleted and the backup container is started again to resume scheduled backups. Otherwise, it stays stopped so that you can fix the issue.

You can start the backup container manually using `docker compose up -d backup`, and see its logs using `docker compose logs -f backup`.

If the backup container is started while the `restore` file still exists, it will print an error and wait for the file to be deleted before it starts scheduling backups again.

## Restoring from an Alternative Location

If you need to restore a backup from an alternative location (for ex. from a daily system backup, as described in the [Retention](#retention) section), do the following:

1. Stop the backup container using `docker compose stop backup`
2. Copy the backup file into the folder where current backups are stored (see [Locations](#locations))
3. Run the restoration script

You must ensure the file is readable and writable by the service's designated database user. If the file in the alternative location already has correct ownership information, use `cp -a` when copying the file to preserve ownership.
