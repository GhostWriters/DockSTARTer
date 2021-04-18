#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup'
    run_script 'override_backup'
    info "Replacing current .env file with latest template."
    local CURRENTENV
    CURRENTENV=$(mktemp) || fatal "Failed to create temporary current .env file.\nFailing command: ${F[C]}mktemp"
    sort "${SCRIPTPATH}/compose/.env" > "${CURRENTENV}" || fatal "Failed to sort to new file.\nFailing command: ${F[C]}sort \"${SCRIPTPATH}/compose/.env\" > \"${CURRENTENV}\""
    local UPDATEDENV
    UPDATEDENV=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    cp "${SCRIPTPATH}/compose/.env.example" "${UPDATEDENV}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.env.example\" \"${UPDATEDENV}\""
    info "Merging current values into updated .env file."
    while IFS= read -r line; do
        local SET_VAR=${line%%=*}
        local SET_VAL=${line#*=}
        if grep -q "^${SET_VAR}=" "${UPDATEDENV}"; then
            run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${UPDATEDENV}"
        else
            echo "${line}" >> "${UPDATEDENV}" || error "${line} could not be written to ${UPDATEDENV}"
        fi
    done < <(grep '=' < "${CURRENTENV}")
    cp -f "${UPDATEDENV}" "${SCRIPTPATH}/compose/.env" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${UPDATEDENV}\" \"${SCRIPTPATH}/compose/.env\""
    run_script 'set_permissions' "${SCRIPTPATH}/compose/.env"
    rm -f "${CURRENTENV}" || warn "Failed to remove temporary .env update file."
    rm -f "${UPDATEDENV}" || warn "Failed to remove temporary .env update file."
    run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_update() {
    run_script 'env_update'
}
