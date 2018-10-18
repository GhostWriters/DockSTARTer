#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_backup() {
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "${SCRIPTPATH}/compose/.env found. Copying to ${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME}"
        mkdir -p "${SCRIPTPATH}/compose/.env.backups" || fatal "${SCRIPTPATH}/compose/.env.backups folder could not be created."
        cp "${SCRIPTPATH}/compose/.env" "${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME}" || fatal "${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME} could not be copied."
        info "Removing old .env backups."
        find "${SCRIPTPATH}/compose/.env.backups/.env.*" -mtime +21 -type f -delete > /dev/null 2>&1 || warning "Old .env backups not removed."
        local PUID
        PUID=$(run_script 'env_get' PUID)
        local PGID
        PGID=$(run_script 'env_get' PGID)
        run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
    else
        run_script 'env_create'
    fi
}
