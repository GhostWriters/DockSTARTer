#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

env_sanitize() {
    local -a VarsToUpdate
    local -A UpdatedVarValue

    # Update the HOME variable if it is not set to the detected home directory
    local HOME
    HOME="$(run_script 'env_get' HOME)"
    if [[ ${HOME} != "${DETECTED_HOMEDIR}" ]]; then
        HOME="${DETECTED_HOMEDIR}"
        VarsToUpdate+=(HOME)
        UpdatedVarValue["HOME"]="${DETECTED_HOMEDIR}"
    fi

    local DOCKER_CONFIG_FOLDER DOCKER_COMPOSE_FOLDER ORIG_CONFIG_FOLDER ORIG_COMPOSE_FOLDER

    ORIG_CONFIG_FOLDER="$(run_script 'env_get' DOCKER_CONFIG_FOLDER)"
    DOCKER_CONFIG_FOLDER="${ORIG_CONFIG_FOLDER}"
    if [[ -z ${DOCKER_CONFIG_FOLDER-} ]]; then
        DOCKER_CONFIG_FOLDER="$(run_script 'var_default_value' DOCKER_CONFIG_FOLDER)"
    fi

    ORIG_COMPOSE_FOLDER="$(run_script 'env_get' DOCKER_COMPOSE_FOLDER)"
    DOCKER_COMPOSE_FOLDER="${ORIG_COMPOSE_FOLDER}"
    if [[ -z ${DOCKER_COMPOSE_FOLDER-} ]]; then
        DOCKER_COMPOSE_FOLDER="$(run_script 'var_default_value' DOCKER_COMPOSE_FOLDER)"
    fi

    LITERAL_CONFIG_FOLDER="${DOCKER_CONFIG_FOLDER}"
    LITERAL_COMPOSE_FOLDER="${DOCKER_COMPOSE_FOLDER}"

    set_global_variables

    if [[ ${ORIG_CONFIG_FOLDER} != "${LITERAL_CONFIG_FOLDER}" ]]; then
        DOCKER_CONFIG_FOLDER="${LITERAL_CONFIG_FOLDER}"
        VarsToUpdate+=(DOCKER_CONFIG_FOLDER)
        UpdatedVarValue["DOCKER_CONFIG_FOLDER"]="${DOCKER_CONFIG_FOLDER}"
    fi
    if [[ ${ORIG_COMPOSE_FOLDER} != "${LITERAL_COMPOSE_FOLDER}" ]]; then
        DOCKER_COMPOSE_FOLDER="${LITERAL_COMPOSE_FOLDER}"
        VarsToUpdate+=(DOCKER_COMPOSE_FOLDER)
        UpdatedVarValue["DOCKER_COMPOSE_FOLDER"]="${DOCKER_COMPOSE_FOLDER}"
    fi

    # Backup the user files
    run_script 'env_backup'

    # Migrate from old global variable names
    run_script 'env_migrate_global'

    # Add any default global variables that might have been deleted
    run_script 'env_merge_newonly' "${COMPOSE_ENV}" "${COMPOSE_ENV_DEFAULT_FILE}"

    local -a VarList

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
        if [[ -z ${Value-} ]] || echo "${Value-}" | ${GREP} -q 'x'; then
            # If the variable is empty or contains an "x", get the default value
            local Default
            Default="$(run_script 'var_default_value' "${VarName}")"
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="${Default}"
        fi
    done

    # Replace ~ with /home/username
    local -a VarList=(
        DOCKER_VOLUME_CONFIG
        DOCKER_VOLUME_STORAGE
        DOCKER_VOLUME_STORAGE2
        DOCKER_VOLUME_STORAGE3
        DOCKER_VOLUME_STORAGE4
    )
    for VarName in "${VarList[@]-}"; do
        # Get the value including quotes
        local Value
        Value="$(run_script 'env_get' "${VarName}")"
        local UpdatedValue
        UpdatedValue="$(run_script 'sanitize_path' "${Value}")"
        UpdatedValue="$(
            replace_with_vars \
                "${UpdatedValue}" \
                DOCKER_CONFIG_FOLDER "${DOCKER_CONFIG_FOLDER}" \
                HOME "${HOME}"
        )"
        if [[ ${Value} != "${UpdatedValue}" ]]; then
            VarsToUpdate+=("${VarName}")
            UpdatedVarValue["${VarName}"]="\"${UpdatedValue}\""
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
