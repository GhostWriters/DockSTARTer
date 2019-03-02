#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup'
    run_script 'override_backup'
    info "Replacing current .env file with latest template."
    local CURRENTENV
    CURRENTENV="$(mktemp)"
    cp "${SCRIPTPATH}/compose/.env" "${CURRENTENV}" || fatal "${SCRIPTPATH}/compose/.env could not be copied."
    rm -f "${SCRIPTPATH}/compose/.env" || warning "${SCRIPTPATH}/compose/.env could not be removed."
    cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "${SCRIPTPATH}/compose/.env.example could not be copied."
    info "Merging previous values into new .env file."
    while IFS= read -r line; do
        local SET_VAR
        SET_VAR=${line%%=*}
        local SET_VAL
        SET_VAL=${line#*=}
        if grep -q "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            run_script 'env_set' "${SET_VAR}" "${SET_VAL}"
        else
            echo "${line}" >> "${SCRIPTPATH}/compose/.env" || error "${line} could not be written to ${SCRIPTPATH}/compose/.env"
        fi
    done < <(grep '=' < "${CURRENTENV}")
    rm -f "${CURRENTENV}" || warning "Temporary .env file could not be removed."
    run_script 'env_sanitize'
    info "Environment file update complete."
    local PUID
    PUID=$(run_script 'env_get' PUID)
    local PGID
    PGID=$(run_script 'env_get' PGID)
    run_script 'set_permissions' "${SCRIPTPATH}" "${PUID}" "${PGID}"
    local DOCKERCONFDIR
    DOCKERCONFDIR=$(run_script 'env_get' DOCKERCONFDIR)
    if [[ ${DOCKERCONFDIR} != ${SCRIPTPATH}* ]]; then
        run_script 'set_permissions' "${DOCKERCONFDIR}" "${PUID}" "${PGID}"
    fi
}

test_env_update() {
    run_script 'env_update'
}
