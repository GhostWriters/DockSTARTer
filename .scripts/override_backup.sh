#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

override_backup() {
    if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
        local DOCKERCONFDIR
        DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying docker-compose.override.yml file to ${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}"
        mkdir -p "${DOCKERCONFDIR}/.compose.backups" || fatal "${DOCKERCONFDIR}/.compose.backups folder could not be created."
        cp "${SCRIPTPATH}/compose/docker-compose.override.yml" "${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME} could not be copied."
        run_script 'set_permissions' "${DOCKERCONFDIR}/.compose.backups"
        info "Removing old docker-compose.override.yml backups."
        find "${DOCKERCONFDIR}/.compose.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete > /dev/null 2>&1 || warning "Old docker-compose.override.yml backups not removed."
    fi
}

test_override_backup() {
    run_script 'override_backup'
}
