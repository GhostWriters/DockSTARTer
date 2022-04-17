#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_backup() {
    run_script 'env_create'
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    info "Taking ownership of ${DOCKERCONFDIR} (non-recursive)."
    chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${DOCKERCONFDIR}" > /dev/null 2>&1 || true
    local BACKUPTIME
    BACKUPTIME=$(date +"%Y%m%d%H%M%S")
    info "Copying .env file to ${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME}"
    mkdir -p "${DOCKERCONFDIR}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${DOCKERCONFDIR}/.compose.backups\""
    cp "${COMPOSE_ENV}" "${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME}" || fatal "Failed to copy backup.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV}\" \"${DOCKERCONFDIR}/.compose.backups/.env.${BACKUPTIME}\""
    run_script 'set_permissions' "${DOCKERCONFDIR}/.compose.backups"
    info "Removing old .env backups."
    find "${DOCKERCONFDIR}/.compose.backups" -type f -name ".env.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old .env backups not removed."

    # Backup location has moved
    if [[ -d "${DOCKERCONFDIR}/.env.backups" ]]; then
        info "Removing old backup location."
        rm -rf "${DOCKERCONFDIR}/.env.backups" || fatal "Failed to remove directory.\nFailing command: ${F[C]}rm -rf \"${DOCKERCONFDIR}/.env.backups\""
    fi
}

test_env_backup() {
    run_script 'env_backup'
}
