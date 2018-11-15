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
    mkdir -p "${DOCKERCONFDIR}/.env.backups" || fatal "${DOCKERCONFDIR}/.env.backups folder could not be created."
    cp "${SCRIPTPATH}/compose/.env" "${DOCKERCONFDIR}/.env.backups/.env.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.env.backups/.env.${BACKUPTIME} could not be copied."
    info "Removing old .env backups."
    find "${DOCKERCONFDIR}/.env.backups" -type f -name ".env.*" -mtime +3 -delete > /dev/null 2>&1 || warning "Old .env backups not removed."
}
