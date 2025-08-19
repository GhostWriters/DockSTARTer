#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_backup() {
    if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
        local DOCKER_VOLUME_CONFIG
        DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
        if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
            fatal "'${C["Var"]}DOCKER_VOLUME_CONFIG${NC}' is not set in '${C["File"]}${COMPOSE_ENV}${NC}'"
        fi
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying '${C["File"]}docker-compose.override.yml${NC}' file to '${C["File"]}${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}${NC}'"
        mkdir -p "${DOCKER_VOLUME_CONFIG}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${C["FailingCommand"]}mkdir -p \"${DOCKER_VOLUME_CONFIG}/.compose.backups\""
        cp "${COMPOSE_FOLDER}/docker-compose.override.yml" "${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "Failed to copy file.\nFailing command: ${C["FailingCommand"]}cp \"${COMPOSE_FOLDER}/docker-compose.override.yml\" \"${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}\""
        run_script 'set_permissions' "${DOCKER_VOLUME_CONFIG}/.compose.backups"
        info "Removing old '${C["File"]}docker-compose.override.yml${NC}' backups."
        find "${DOCKER_VOLUME_CONFIG}/.compose.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old '${C["File"]}docker-compose.override.yml${NC}' backups not removed."
    fi
}

test_override_backup() {
    run_script 'override_backup'
}
