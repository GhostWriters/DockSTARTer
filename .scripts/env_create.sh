#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_create() {
    local -a DefaultApps=(
        WATCHTOWER
    )

    if [[ -f ${COMPOSE_OVERRIDE} ]]; then
        run_script 'set_permissions' "${COMPOSE_OVERRIDE}"
    fi

    if [[ -e ${APP_ENV_FOLDER} ]]; then
        if [[ -d ${APP_ENV_FOLDER} ]]; then
            info "${APP_ENV_FOLDER} found."
        else
            fatal "${APP_ENV_FOLDER} is a file, should be a folder"
        fi
    else
        warn "Folder ${APP_ENV_FOLDER} not found. Creating it."
        mkdir -p "${APP_ENV_FOLDER}" ||
            fatal "Failed to create folder.\nFailing command: ${F[C]}mkdir -p \"${APP_ENV_FOLDER}\""
    fi
    run_script 'set_permissions' "${APP_ENV_FOLDER}"

    run_script 'env_backup'
    if [[ -f ${COMPOSE_ENV} ]]; then
        info "${COMPOSE_ENV} found."
        run_script 'env_sanitize'
    else
        warn "${COMPOSE_ENV} not found. Copying example template."
        cp "${COMPOSE_ENV_DEFAULT_FILE}" "${COMPOSE_ENV}" ||
            fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV_DEFAULT_FILE}\" \"${COMPOSE_ENV}\""
        run_script 'set_permissions' "${COMPOSE_ENV}"
        run_script 'env_sanitize'
        if [[ -n ${DefaultApps-} && -z $(run_script 'app_list_referenced') ]]; then
            info "Installing default applications."
        #   run_script 'appvars_create' "${DefaultApps[@]}"
            run_script 'env_sanitize'
        fi
    fi
}

test_env_create() {
    run_script 'env_create'
    cat "${COMPOSE_ENV}"
}
