#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
    run_script 'env_backup'
    run_script 'override_backup'
    info "Replacing current .env file with latest template."
    local MKTEMP_ENV_CURRENT
    MKTEMP_ENV_CURRENT=$(mktemp) || fatal "Failed to create temporary current .env file.\nFailing command: ${F[C]}mktemp"
    sort "${SCRIPTPATH}/compose/.env" > "${MKTEMP_ENV_CURRENT}" || fatal "Failed to sort to new file.\nFailing command: ${F[C]}sort \"${SCRIPTPATH}/compose/.env\" > \"${MKTEMP_ENV_CURRENT}\""
    local MKTEMP_ENV_UPDATED
    MKTEMP_ENV_UPDATED=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    cp "${SCRIPTPATH}/compose/.env.example" "${MKTEMP_ENV_UPDATED}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.env.example\" \"${MKTEMP_ENV_UPDATED}\""
    info "Merging current values into updated .env file."
    while IFS= read -r line; do
        local SET_VAR=${line%%=*}
        local SET_VAL=${line#*=}
        if grep -q "^${SET_VAR}=" "${MKTEMP_ENV_UPDATED}"; then
            run_script 'env_set' "${SET_VAR}" "${SET_VAL}" "${MKTEMP_ENV_UPDATED}"
        else
            echo "${line}" >> "${MKTEMP_ENV_UPDATED}" || error "${line} could not be written to ${MKTEMP_ENV_UPDATED}"
        fi
    done < <(grep '=' < "${MKTEMP_ENV_CURRENT}")
    rm -f "${MKTEMP_ENV_CURRENT}" || warn "Failed to remove temporary .env update file."
    cp -f "${MKTEMP_ENV_UPDATED}" "${SCRIPTPATH}/compose/.env" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${SCRIPTPATH}/compose/.env\""
    rm -f "${MKTEMP_ENV_UPDATED}" || warn "Failed to remove temporary .env update file."
    run_script 'set_permissions' "${SCRIPTPATH}/compose/.env"
    run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_update() {
    run_script 'env_update'
}
