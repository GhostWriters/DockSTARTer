#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Backup the user files
    run_script 'env_backup'
    # Migrate from old global variable names
    run_script 'env_migrate_global'
    # Copy any variables that might have been deleted
    run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${COMPOSE_ENV_DEFAULT_FILE}"
    local -a VarsToUpdate
    local -A UpdatedVarValue
    # Set defaults for some "special cases" of the global variables
    for VarName in DOCKER_HOSTNAME TZ; do
        local Value
        Value="$(run_script 'env_get' "${VarName}")"
        if [[ -z ${Value-} ]]; then
            # If the variable is empty get the default value
            local Default
            Default="$(run_script 'var_default_value' "${VarName}")"
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="${Default}"
        fi
    done
    for VarName in GLOBAL_LAN_NETWORK DOCKER_GID PGID PUID; do
        local Value
        Value="$(run_script 'env_get' "${VarName}")"
        if [[ -z ${Value-} ]] || echo "${Value-}" | grep -q 'x'; then
            # If the variable is empty or contains an "x", get the default value
            local Default
            Default="$(run_script 'var_default_value' "${VarName}")"
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="${Default}"
        fi
    done

    # Don't set WATCHTOWER_NETWORK_MODE to none
    local WATCHTOWER_NETWORK_MODE
    WATCHTOWER_NETWORK_MODE="$(run_script 'env_get' WATCHTOWER__NETWORK_MODE)"
    if [[ ${WATCHTOWER_NETWORK_MODE-} == "none" ]]; then
        VarsToUpdate+=("WATCHTOWER_NETWORK_MODE")
        UpdatedVarValue["WATCHTOWER_NETWORK_MODE"]="''"
    fi

    # Replace ~ with /home/username
    # Start with the global volume variables
    local -a VarList=(
        "DOCKER_VOLUME_CONFIG"
        "DOCKER_VOLUME_STORAGE"
        "DOCKER_VOLUME_STORAGE2"
        "DOCKER_VOLUME_STORAGE3"
        "DOCKER_VOLUME_STORAGE4"
    )
    # Add any "APPNAME__VOLUME_*" variables to the list
    local -a AppList
    readarray -t AppList < <(run_script 'app_list_referenced')
    for AppName in "${AppList[@]-}"; do
        readarray -t -O ${#VarList[@]} VarList < <(
            grep -o -P "^\s*\K${AppName^^}__VOLUME_[a-zA-Z0-9]+[a-zA-Z0-9_]*(?=\s*=)" "${COMPOSE_ENV}" || true
        )
    done
    for VarName in "${VarList[@]-}"; do
        # Get the value including quotes
        local Value
        Value="$(run_script 'env_get_literal' "${VarName}")"
        if [[ ${Value} == *~* ]]; then
            # Value contains a "~", repace it with the user's home directory
            Value="${Value//\~/"${DETECTED_HOMEDIR}"}"
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="${Value}"
        fi
    done
    if [[ -n ${VarsToUpdate[*]-} ]]; then
        notice "Setting variables in ${C["File"]}${COMPOSE_ENV}${NC}:"
        for VarName in "${VarsToUpdate[@]}"; do
            local Value="${UpdatedVarValue["${VarName}"]}"
            notice "   ${C["Var"]}${VarName}=${Value}${NC}"
            run_script 'env_set_literal' "${VarName}" "${Value}"
        done
    fi
}

test_env_sanitize() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'appvars_purge' WATCHTOWER
}
