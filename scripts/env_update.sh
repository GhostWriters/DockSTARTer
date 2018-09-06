#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup' menu
    info "Locating newest .env file backup."
    local NEWEST_ENV
    for f in "${SCRIPTPATH}"/compose/.env.backups/.env.*; do
        [[ -f "${f}" ]] && NEWEST_ENV=${f} || NEWEST_ENV=false
    done
    if [[ ${NEWEST_ENV} != false ]]; then
        info "Replacing current .env file with latest template."
        rm -f "${SCRIPTPATH}/compose/.env" || warning "${SCRIPTPATH}/compose/.env could not be removed."
        cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "${SCRIPTPATH}/compose/.env could not be copied."
        local PUID
        PUID=$(run_script 'env_get' PUID)
        local PGID
        PGID=$(run_script 'env_get' PGID)
        run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
        info "Writing values from .env file backup."
        while IFS= read -r line; do
            local SET_VAR
            SET_VAR=${line/=*/}
            local SET_VAL
            SET_VAL=${line/*=/}
            if grep -q "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
                run_script 'env_set' "${SET_VAR}" "${SET_VAL}"
            else
                echo "${line}" >> "${SCRIPTPATH}/compose/.env"
            fi
        done < <(grep '=' < "${NEWEST_ENV}")
        info "Environment file update complete."
    else
        error "No .env file backups found in ${SCRIPTPATH}/compose/.env.backups/"
    fi
}
