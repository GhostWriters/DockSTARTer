#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_backup() {
    run_script 'env_create'
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${DOCKERCONFDIR}" > /dev/null 2>&1 || true
    local BACKUPTIME
    BACKUPTIME=$(date +"%Y%m%d%H%M%S")
    info "Copying .env file to ${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME}"
    mkdir -p "${DOCKERCONFDIR}/.compose.backups" || fatal "${DOCKERCONFDIR}/.compose.backups folder could not be created."
    cp "${SCRIPTPATH}/compose/.env" "${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME} could not be copied."
    run_script 'set_permissions' "${DOCKERCONFDIR}/.compose.backups"
    info "Removing old .env backups."
    find "${DOCKERCONFDIR}/.compose.backups" -type f -name ".env.*" -mtime +3 -delete > /dev/null 2>&1 || warning "Old .env backups not removed."

    # Backup location has moved
    if [[ -d "${DOCKERCONFDIR}/.env.backups" ]]; then
        info "Removing old backup location."
        rm -rf "${DOCKERCONFDIR}/.env.backups" || fatal "Failed to remove the ${DOCKERCONFDIR}/.env.backups folder."
    fi
}

test_env_backup() {
    run_script 'env_backup'
}
