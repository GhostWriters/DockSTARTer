#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update_testing() {
    local ENV_LINES_FILE
    ENV_LINES_FILE=$(mktemp)

    run_script 'appvars_lines' "" > "${ENV_LINES_FILE}"
    run_script 'env_format_lines' "${ENV_LINES_FILE}" "${COMPOSE_ENV_DEFAULT_FILE}" ""
    APPS=$(run_script 'app_list_referenced')
    for APPNAME in ${APPS^^}; do
        local appname=${APPNAME,,}
        local APP_ENV_FILE="${APP_ENV_FOLDER}/${appname}.env"
        local APP_DEFAULT_GLOBAL_ENV_FILE=""
        local APP_DEFAULT_ENV_FILE=""
        if run_script 'app_is_installed' "${APPNAME}"; then
            APP_DEFAULT_GLOBAL_ENV_FILE="${TEMPLATES_FOLDER}/${appname}/.env"
            APP_DEFAULT_ENV_FILE="${TEMPLATES_FOLDER}/${appname}/${appname}.env"
        fi
        #run_script 'appvars_lines' "${APPNAME}" > "${ENV_LINES_FILE}"
        #run_script 'env_format_lines' "${ENV_LINES_FILE}" "${APP_DEFAULT_GLOBAL_ENV_FILE}" "${APPNAME}"
        run_script 'env_format_lines' "${APP_ENV_FILE}" "${APP_DEFAULT_ENV_FILE}" "${APPNAME}"
    done

    #local MKTEMP_ENV_UPDATED
    #MKTEMP_ENV_UPDATED=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    #printf '%s\n' "${UPDATED_ENV_LINES[@]}" > "${MKTEMP_ENV_UPDATED}" || fatal "Failed to write temporary ${FILENAME}.env update file."

    #cp -f "${MKTEMP_ENV_UPDATED}" "${APP_ENV_FILE}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${APP_ENV_FILE}\""
    #rm -f "${MKTEMP_ENV_UPDATED}" || warn "Failed to remove temporary ${FILENAME}.env update file.\nFailing command: ${F[C]}rm -f \"${MKTEMP_ENV_UPDATED}\""
    #run_script 'set_permissions' "${APP_ENV_FILE}"
    #run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_update_testing() {
    run_script 'env_update_testing'
    #warn "CI does not test env_update_testing."
}
