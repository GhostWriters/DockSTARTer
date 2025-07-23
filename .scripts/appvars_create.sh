#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList^^}; do
        local appname=${APPNAME,,}
        local AppName
        AppName="$(run_script 'app_nicename' "${APPNAME}")"

        if ! run_script 'appname_is_valid' "${appname}"; then
            error "${F[C]}${AppName}${NC} is not a valid application name."
            continue
        fi
        if run_script 'app_is_builtin' "${AppName}"; then
            local AppDefaultGlobalEnvFile AppDefaultAppEnvFile AppEnvFile
            AppDefaultGlobalEnvFile="$(run_script 'app_instance_file' "${appname}" ".global.env")"
            AppDefaultAppEnvFile="$(run_script 'app_instance_file' "${appname}" ".app.env")"
            AppEnvFile="$(run_script 'app_env_file' "${appname}")"

            info "Creating environment variables for ${F[C]}${AppName}${NC}."

            if ! run_script 'env_var_exists' "${APPNAME}_ENABLED"; then
                run_script 'env_migrate' "${APPNAME}_ENABLED" "${APPNAME}__ENABLED"
            fi
            if ! run_script 'app_is_added' "${APPNAME}"; then
                run_script 'enable_app' "${APPNAME}"
            fi

            run_script 'appvars_migrate' "${APPNAME}"

            run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${AppDefaultGlobalEnvFile}"
            run_script 'env_merge_newonly' "${AppEnvFile}" "${AppDefaultAppEnvFile}"
            info "Environment variables created for ${F[C]}${AppName}${NC}."
        else
            warn "Application ${F[C]}${AppName}${NC} does not exist."
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
