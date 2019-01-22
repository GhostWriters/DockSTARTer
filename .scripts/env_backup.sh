#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_backup() {
    run_script 'env_create'
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    local BACKUPTIME
    BACKUPTIME=$(date +"%Y%m%d%H%M%S")
    info "Copying .env file to ${DOCKERCONFDIR}/.env.backups/.env.${BACKUPTIME}"
    run_cmd mkdir -p "${DOCKERCONFDIR}/.env.backups" || fatal "${DOCKERCONFDIR}/.env.backups folder could not be created."
    run_cmd cp "${SCRIPTPATH}/compose/.env" "${DOCKERCONFDIR}/.env.backups/.env.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.env.backups/.env.${BACKUPTIME} could not be copied."
    info "Removing old .env backups."
    run_cmd find "${DOCKERCONFDIR}/.env.backups" -type f -name ".env.*" -mtime +3 -delete || warning "Old .env backups not removed."
}
