#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}

    local FILENAME=${APPNAME,,}
    local APP_FOLDER="${TEMPLATES_FOLDER}/${FILENAME}"
    local APP_DEFAULT_GLOBAL_ENV_FILE="${APP_FOLDER}/.env"
    local APP_DEFAULT_ENV_FILE="${APP_FOLDER}/${FILENAME}.env"
    local APP_ENV_FILE="${APP_ENV_FOLDER}/${FILENAME}.env"

    info "Creating environment variables for ${APPNAME}."
    
    if ! run_script 'env_var_exists' "${APPNAME}__ENABLED"; then
        run_script 'env_set' "${APPNAME}__ENABLED" true
    fi

    if run_script 'app_is_enabled' "${APPNAME}"; then
        run_script 'appvars_migrate' "${APPNAME}"
    fi

    run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${APP_DEFAULT_GLOBAL_ENV_FILE}"
    run_script 'env_merge_newonly' "${APP_ENV_FILE}" "${APP_DEFAULT_ENV_FILE}"
}

test_appvars_create() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_update'
    echo "${COMPOSE_ENV}:"
    cat "${COMPOSE_ENV}"
    echo "${APP_ENV_FOLDER}/watchtower.env:"
    cat "${APP_ENV_FOLDER}/watchtower.env"
}
