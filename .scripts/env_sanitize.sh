#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Migrate from old global variable names
    run_script 'env_migrate_global'
    # Set defaults for some "special cases" of the global variables
    for VarName in GLOBAL_LAN_NETWORK DOCKER_GID PGID PUID; do
        local Value
        Value="$(run_script 'env_get_literal' "${VarName}")"
        if [[ -z ${Value-} ]] || echo "${Value-}" | grep -q 'x'; then
            # If the variable is empty or contains an "x", get the default value
            run_script 'env_set_literal' "${VarName}" "$(run_script 'var_default_value' "${VarName}"))"
        fi
    done
    # Copy any other variables that might have been deleted
    run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${COMPOSE_ENV_DEFAULT_FILE}"

    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE="$(run_script 'env_get' WATCHTOWER__NETWORK_MODE)"
    if [[ ${WATCHTOWER_NETWORK_MODE-} == "none" ]]; then
        run_script 'env_set' WATCHTOWER__NETWORK_MODE ""
    fi

    # Replace ~ with /home/username
    # Start with the two global volume variables
    local -a VarList=(
        "DOCKER_VOLUME_CONFIG"
        "DOCKER_VOLUME_COMPOSE"
    )
    # Add any "APPNAME__VOLUME_*" variables to the list
    local -a AppList
    readarray -t AppList < <(run_script 'app_list_referenced')
    for AppName in ${AppList[@]}; do
        readarray -t -O ${#VarList[@]} VarList < <(grep -o -P "^\s*\K${AppName}__VOLUME_[a-zA-Z0-9]+[a-zA-Z0-9_](?=\s*=)")
    done
    for VarName in ${VarList[@}}; do
        # Get the value including quotes
        Value="$(run_script 'env_get_literal' "${VarName}")"
        if [[ ${Value} == ~* ]]; then
            # Value contains a "~", repace it with the user's home directory
            local CorrectedValue
            CorrectedValue="$(sed "s|~|${DETECTED_HOMEDIR}|g" <<< "${Value}")"
            info "Replacing ~ with ${DETECTED_HOMEDIR} in ${VarName}."
            run_script 'env_set_literal' "${VarName}" "${CorrectedValue}"
        fi
    done
}

test_env_sanitize() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_sanitize'
    run_script 'appvars_purge' WATCHTOWER
}
