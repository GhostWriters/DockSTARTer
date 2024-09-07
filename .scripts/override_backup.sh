#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_backup() {
    if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
        local DOCKER_VOLUME_CONFIG
        DOCKER_VOLUME_CONFIG=$(run_script 'env_get' DOCKER_VOLUME_CONFIG)
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying docker-compose.override.yml file to ${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}"
        mkdir -p "${DOCKER_VOLUME_CONFIG}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${DOCKER_VOLUME_CONFIG}/.compose.backups\""
        cp "${SCRIPTPATH}/compose/docker-compose.override.yml" "${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/docker-compose.override.yml\" \"${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}\""
        run_script 'set_permissions' "${DOCKER_VOLUME_CONFIG}/.compose.backups"
        info "Removing old docker-compose.override.yml backups."
        find "${DOCKER_VOLUME_CONFIG}/.compose.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old docker-compose.override.yml backups not removed."
    fi
}

test_override_backup() {
    run_script 'override_backup'
}
