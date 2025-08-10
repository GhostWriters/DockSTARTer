#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_sanitize() {
    # Backup the user files
    run_script 'env_backup'

    # Migrate from old global variable names
    run_script 'env_migrate_global'

    # Add any default global variables that might have been deleted
    run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${COMPOSE_ENV_DEFAULT_FILE}"
    local -a VarsToUpdate
    local -A UpdatedVarValue
    local VarList

    # Set defaults for some "special cases" of the global variables
    VarList=(
        DOCKER_HOSTNAME
        TZ
    )
    for VarName in "${VarList[@]-}"; do
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

    VarList=(
        GLOBAL_LAN_NETWORK
        DOCKER_GID
        PGID
        PUID
    )
    for VarName in "${VarList[@]-}"; do
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

    # Replace ~ with /home/username
    local -a VarList=(
        "DOCKER_VOLUME_CONFIG"
        "DOCKER_VOLUME_STORAGE"
        "DOCKER_VOLUME_STORAGE2"
        "DOCKER_VOLUME_STORAGE3"
        "DOCKER_VOLUME_STORAGE4"
    )
    for VarName in "${VarList[@]-}"; do
        # Get the value including quotes
        local Value
        Value="$(run_script 'env_get_literal' "${VarName}")"
        local UpdatedValue
        UpdatedValue="$(run_script 'sanitize_path' "${Value}")"
        if [[ ${Value} != "${UpdatedValue}" ]]; then
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="${UpdatedValue}"
        fi
    done

    # Process the variable value changes
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
