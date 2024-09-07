#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_backup() {
    run_script 'env_create'
    local DOCKER_VOLUME_CONFIG
    DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
    info "Taking ownership of ${DOCKER_VOLUME_CONFIG} (non-recursive)."
    sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${DOCKER_VOLUME_CONFIG}" > /dev/null 2>&1 || true
    local BACKUPTIME
    BACKUPTIME=$(date +"%Y%m%d%H%M%S")
    info "Copying .env file to ${DOCKER_VOLUME_CONFIG}/.compose.backups/.env.${BACKUPTIME}"
    mkdir -p "${DOCKER_VOLUME_CONFIG}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${DOCKER_VOLUME_CONFIG}/.compose.backups\""
    cp "${COMPOSE_ENV}" "${DOCKER_VOLUME_CONFIG}/.compose.backups/.env.${BACKUPTIME}" || fatal "Failed to copy backup.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV}\" \"${DOCKER_VOLUME_CONFIG}/.compose.backups/.env.${BACKUPTIME}\""
    run_script 'set_permissions' "${DOCKER_VOLUME_CONFIG}/.compose.backups"
    info "Removing old .env backups."
    find "${DOCKER_VOLUME_CONFIG}/.compose.backups" -type f -name ".env.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old .env backups not removed."

    # Backup location has moved
    if [[ -d "${DOCKER_VOLUME_CONFIG}/.env.backups" ]]; then
        info "Removing old backup location."
        rm -rf "${DOCKER_VOLUME_CONFIG}/.env.backups" || fatal "Failed to remove directory.\nFailing command: ${F[C]}rm -rf \"${DOCKER_VOLUME_CONFIG}/.env.backups\""
    fi
}

test_env_backup() {
    run_script 'env_backup'
}
