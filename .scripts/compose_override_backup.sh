#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

compose_override_backup() {
    if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
        local DOCKERCONFDIR
        DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying docker-compose.override.yml file to ${DOCKERCONFDIR}/.env.backups/docker-compose.override.yml.${BACKUPTIME}"
        mkdir -p "${DOCKERCONFDIR}/.env.backups" || fatal "${DOCKERCONFDIR}/.env.backups folder could not be created."
        cp "${SCRIPTPATH}/compose/docker-compose.override.yml" "${DOCKERCONFDIR}/.env.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.env.backups/docker-compose.override.yml.${BACKUPTIME} could not be copied."
        info "Removing old docker-compose.override.yml backups."
        find "${DOCKERCONFDIR}/.env.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete > /dev/null 2>&1 || warning "Old docker-compose.override.yml backups not removed."
    fi
}
