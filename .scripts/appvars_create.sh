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
            local AppDefaultGlobalEnvFile AppDefaultAppEnvFile AppEnvFile
            AppDefaultGlobalEnvFile="$(run_script 'app_instance_file' "${appname}" ".global.env")"
            AppDefaultAppEnvFile="$(run_script 'app_instance_file' "${appname}" ".app.env")"
            AppEnvFile="$(run_script 'app_env_file' "${appname}")"

            info "Creating environment variables for ${AppName}."

            if ! run_script 'env_var_exists' "${APPNAME}__ENABLED"; then
                run_script 'env_set' "${APPNAME}__ENABLED" true
            fi

            run_script 'appvars_migrate' "${APPNAME}"

            run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${AppDefaultGlobalEnvFile}"
            run_script 'env_merge_newonly' "${AppEnvFile}" "${AppDefaultAppEnvFile}"
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
    local EnvFile
    EnvFile="$(run_script 'app_env_file' "watchtower")"
    echo "${EnvFile}:"
    cat "${EnvFile}"
}
