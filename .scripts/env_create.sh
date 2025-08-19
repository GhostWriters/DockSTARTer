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
            info "${F[C]}${APP_ENV_FOLDER}${NC} found."
        else
            fatal "'${F[C]}${APP_ENV_FOLDER}${NC}' is a file, should be a folder"
        fi
        run_script 'set_permissions' "${APP_ENV_FOLDER}"
    fi

    run_script 'env_backup'
    if [[ -f ${COMPOSE_ENV} ]]; then
        info "${F[C]}${COMPOSE_ENV}${NC} found."
        run_script 'env_sanitize'
    else
        warn "${F[C]}${COMPOSE_ENV}${NC} not found. Copying example template."
        cp "${COMPOSE_ENV_DEFAULT_FILE}" "${COMPOSE_ENV}" ||
            fatal "Failed to copy file.\nFailing command: ${C["FailingCommand"]}cp \"${COMPOSE_ENV_DEFAULT_FILE}\" \"${COMPOSE_ENV}\""
        run_script 'set_permissions' "${COMPOSE_ENV}"
        run_script 'env_sanitize'
        if [[ -n ${DefaultApps-} && -z $(run_script 'app_list_referenced') ]]; then
            info "Installing default applications."
            run_script 'appvars_create' "${DefaultApps[@]}"
            run_script 'env_sanitize'
        fi
    fi
}

test_env_create() {
    run_script 'env_create'
    cat "${COMPOSE_ENV}"
}
