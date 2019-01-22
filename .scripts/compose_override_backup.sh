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
        run_cmd mkdir -p "${DOCKERCONFDIR}/.env.backups" || fatal "${DOCKERCONFDIR}/.env.backups folder could not be created."
        run_cmd cp "${SCRIPTPATH}/compose/docker-compose.override.yml" "${DOCKERCONFDIR}/.env.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.env.backups/docker-compose.override.yml.${BACKUPTIME} could not be copied."
        info "Removing old docker-compose.override.yml backups."
        run_cmd find "${DOCKERCONFDIR}/.env.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete || warning "Old docker-compose.override.yml backups not removed."
    fi
}
