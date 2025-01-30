#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_backup() {
    if [[ -f ${COMPOSE_OVERRIDE} ]]; then
        local DOCKER_VOLUME_CONFIG
        DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying ${COMPOSE_OVERRIDE_NAME} file to ${DOCKER_VOLUME_CONFIG}/.compose.backups/${COMPOSE_OVERRIDE_NAME}.${BACKUPTIME}"
        mkdir -p "${DOCKER_VOLUME_CONFIG}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${DOCKER_VOLUME_CONFIG}/.compose.backups\""
        cp "${COMPOSE_OVERRIDE}" "${DOCKER_VOLUME_CONFIG}/.compose.backups/${COMPOSE_OVERRIDE_NAME}.${BACKUPTIME}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${COMPOSE_OVERRIDE}\" \"${DOCKER_VOLUME_CONFIG}/.compose.backups/${COMPOSE_OVERRIDE_NAME}.${BACKUPTIME}\""
        run_script 'set_permissions' "${DOCKER_VOLUME_CONFIG}/.compose.backups"
        info "Removing old ${COMPOSE_OVERRIDE_NAME} backups."
        find "${DOCKER_VOLUME_CONFIG}/.compose.backups" -type f -name "${COMPOSE_OVERRIDE_NAME}.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old ${COMPOSE_OVERRIDE_NAME} backups not removed."
    fi
}

test_override_backup() {
    run_script 'override_backup'
}
