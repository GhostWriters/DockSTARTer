#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_backup() {
    local PROMPT
    PROMPT=${1:-}
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        local BACKUPTIME
        BACKUPTIME=$(date +"%Y%m%d%H%M%S")
        info "${SCRIPTPATH}/compose/.env found. Copying to ${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME}"
        mkdir -p "${SCRIPTPATH}/compose/.env.backups" || fatal "${SCRIPTPATH}/compose/.env.backups folder could not be created."
        cp "${SCRIPTPATH}/compose/.env" "${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME}" || fatal "${SCRIPTPATH}/compose/.env.backups/.env.${BACKUPTIME} could not be copied."
        info "Removing old .env backups."
        find "${SCRIPTPATH}/compose/.env.backups/.env.*" -mtime +21 -type f -delete || error "Failed to remove old .env backups."
        local PUID
        PUID=$(run_script 'env_get' PUID)
        local PGID
        PGID=$(run_script 'env_get' PGID)
        run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
    else
        run_script 'env_create' "${PROMPT}"
    fi
}
