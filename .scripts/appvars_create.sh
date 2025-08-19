#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create() {
    local AppList
    AppList="$(xargs -n 1 <<< "$*")"
    for APPNAME in ${AppList^^}; do
        local -l appname=${APPNAME}
        local AppName
        AppName="$(run_script 'app_nicename' "${APPNAME}")"

        if ! run_script 'appname_is_valid' "${appname}"; then
            error "'${C["App"]}${AppName}${NC}' is not a valid application name."
            continue
        fi
        if run_script 'app_is_builtin' "${AppName}"; then
            local AppDefaultGlobalEnvFile AppDefaultAppEnvFile AppEnvFile
            AppDefaultGlobalEnvFile="$(run_script 'app_instance_file' "${appname}" ".env")"
            AppDefaultAppEnvFile="$(run_script 'app_instance_file' "${appname}" ".env.app.*")"
            AppEnvFile="$(run_script 'app_env_file' "${appname}")"

            info "Creating environment variables for '${C["App"]}${AppName}${NC}'."
            if ! run_script 'env_var_exists' "${APPNAME}_ENABLED"; then
                run_script 'env_migrate' "${APPNAME}_ENABLED" "${APPNAME}__ENABLED"
            fi
            if ! run_script 'app_is_added' "${AppName}"; then
                run_script 'enable_app' "${AppName}"
            fi
            run_script 'appvars_migrate' "${AppName}"
            run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${AppDefaultGlobalEnvFile}"
            run_script 'env_merge_newonly' "${AppEnvFile}" "${AppDefaultAppEnvFile}"
            run_script 'appvars_sanitize' "${AppName}"
            info "Environment variables created for '${C["App"]}${AppName}${NC}'."
        else
            warn "Application '${C["App"]}${AppName}${NC}' does not exist."
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
