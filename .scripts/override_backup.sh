#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

override_backup() {
    if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
        local DOCKERCONFDIR
        DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "Copying docker-compose.override.yml file to ${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}"
        mkdir -p "${DOCKERCONFDIR}/.compose.backups" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${DOCKERCONFDIR}/.compose.backups\""
        cp "${SCRIPTPATH}/compose/docker-compose.override.yml" "${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/docker-compose.override.yml\" \"${DOCKERCONFDIR}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}\""
        run_script 'set_permissions' "${DOCKERCONFDIR}/.compose.backups"
        info "Removing old docker-compose.override.yml backups."
        find "${DOCKERCONFDIR}/.compose.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete > /dev/null 2>&1 || warn "Old docker-compose.override.yml backups not removed."
    fi
}

test_override_backup() {
    run_script 'override_backup'
}
