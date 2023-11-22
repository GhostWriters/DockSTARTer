# pgBackup

[![Docker Pulls](https://img.shields.io/docker/pulls/prodrigestivill/postgres-backup-local?style=flat-square&color=607D8B&label=docker%20pulls&logo=docker)](https://hub.docker.com/r/prodrigestivill/postgres-backup-local)
[![GitHub Stars](https://img.shields.io/github/stars/prodrigestivill/docker-postgres-backup-local?style=flat-square&color=607D8B&label=github%20stars&logo=github)](https://github.com/prodrigestivill/docker-postgres-backup-local)
[![Compose Templates](https://img.shields.io/static/v1?style=flat-square&color=607D8B&label=compose&message=templates)](https://github.com/GhostWriters/DockSTARTer/tree/master/compose/.apps/pgbackup)

## Description

[pgBackup](https://hub.docker.com/r/prodrigestivill/postgres-backup-local): Backup PostgresSQL to the local filesystem with periodic rotating backups

## Install/Setup

Set your postgres host, username and password in the .env file along with a comma seperated list of databases you want to backup.

By default, backups run daily. Change PGBACKUP_SCHEDULE to any valid [cron schedule](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules) to modify the default.

### Recommended docker-compose overrides

For extra security, it is recommended to limit permissions on the backup folder to a priviledged user. Modify docker-compose.override.yml as below.

If you are using postgres docker container, add a dependency to the container

```yaml
  pgbackup:
    user: postgres:postgres
    depends_on:
      - postgres
```

## Manually trigger a backup

`docker exec -it pgbackup ./backup.sh`

## Restore from latest backup

If the database already exists, drop it.
Create a database <db_name>

```bash
docker exec -it <postgres_container> /bin/sh -c "zcat /storage/backups/postgres/last/<db_name>-latest.sql.gz | psql --username=<username> --dbname=<db_name> -W"
```
