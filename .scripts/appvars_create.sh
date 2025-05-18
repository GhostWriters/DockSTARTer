#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for APPNAME in ${AppList^^}; do
        local appname=${APPNAME,,}
        local AppName
        AppName=$(run_script 'app_nicename' "${APPNAME}")

        if ! run_script 'appname_is_valid' "${appname}"; then
            error "${AppName} is not a valid application name."
            continue
        fi
        if run_script 'app_is_builtin' "${AppName}"; then
            local APP_DEFAULT_GLOBAL_ENV_FILE APP_DEFAULT_ENV_FILE APP_ENV_FILE
            APP_DEFAULT_GLOBAL_ENV_FILE="$(run_script 'instance_file' "${appname}" ".global.env")"
            APP_DEFAULT_ENV_FILE="$(run_script 'instance_file' "${appname}" ".app.env")"
            APP_ENV_FILE="${APP_ENV_FOLDER}/${appname}.env"

            info "Creating environment variables for ${AppName}."

            if [[ ! -d ${APP_ENV_FOLDER} ]]; then
                warn "Folder ${APP_ENV_FOLDER} not found. Creating it."
                mkdir -p "${APP_ENV_FOLDER}" ||
                    fatal "Failed to create folder.\nFailing command: ${F[C]}mkdir -p \"${APP_ENV_FOLDER}\""
            fi

            if ! run_script 'env_var_exists' "${APPNAME}__ENABLED"; then
                run_script 'env_set' "${APPNAME}__ENABLED" true
            fi

            run_script 'appvars_migrate' "${APPNAME}"

            run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${APP_DEFAULT_GLOBAL_ENV_FILE}"
            run_script 'env_merge_newonly' "${APP_ENV_FILE}" "${APP_DEFAULT_ENV_FILE}"
            info "Environment variables created for ${AppName}."
        else
            warn "Application ${AppName} does not exist."
        fi
    done
}

test_appvars_create() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_update'
    echo "${COMPOSE_ENV}:"
    cat "${COMPOSE_ENV}"
    echo "${APP_ENV_FOLDER}/watchtower.env:"
    cat "${APP_ENV_FOLDER}/watchtower.env"
}
