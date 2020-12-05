#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup'
    run_script 'override_backup'
    info "Replacing current .env file with latest template."
    local CURRENTENV
    CURRENTENV=$(mktemp) || fatal "Failed to create temporary .env update file.\nFailing command: ${F[C]}mktemp"
    sort "${SCRIPTPATH}/compose/.env" > "${CURRENTENV}" || fatal "Failed to sort to new file.\nFailing command: ${F[C]}sort \"${SCRIPTPATH}/compose/.env\" > \"${CURRENTENV}\""
    rm -f "${SCRIPTPATH}/compose/.env" || warn "${SCRIPTPATH}/compose/.env could not be removed."
    cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.env.example\" \"${SCRIPTPATH}/compose/.env\""
    run_script 'set_permissions' "${SCRIPTPATH}/compose/.env"
    info "Merging previous values into new .env file."
    while IFS= read -r line; do
        local SET_VAR=${line%%=*}
        local SET_VAL=${line#*=}
        if grep -q "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env"; then
            run_script 'env_set' "${SET_VAR}" "${SET_VAL}"
        else
            echo "${line}" >> "${SCRIPTPATH}/compose/.env" || error "${line} could not be written to ${SCRIPTPATH}/compose/.env"
        fi
    done < <(grep '=' < "${CURRENTENV}")
    rm -f "${CURRENTENV}" || warn "Failed to remove temporary .env update file."
    run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_update() {
    run_script 'env_update'
}
