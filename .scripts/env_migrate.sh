#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_migrate() {
    local FromVar=${1-}
    local ToVar=${2-}
    local FromVarFile=${3:-$COMPOSE_ENV}
    local ToVarFile=${4:-$FromVarFile}

    # Change the .env file to use `appname.env' if 'appname:' preceeds the variable name, and remove 'appname:' from the string
    if [[ ${FromVar} == *":"* ]]; then
        FromVarFile="${APP_ENV_FOLDER}/${FromVar%:*}.env"
        FromVar="${FromVar#*:}"
    fi
    if [[ ${ToVar} == *":"* ]]; then
        ToVarFile="${APP_ENV_FOLDER}/${ToVar%:*}.env"
        ToVar="${ToVar#*:}"
    fi

    if [[ ! -f ${ToVarFile} ]]; then
        # Destination file does not exist, create it
        notice "Creating ${ToVarFile}"
        touch "${ToVarFile}"
    fi

    if [[ ${FromVarFile} == "${ToVarFile}" ]]; then
        # Renaming variables in the same file (possibly handle override migrations here)
        local VarFile=${FromVarFile}
        local -a FoundVarList=()
        readarray -t FoundVarList < <(grep -o -P "^\s*\K${FromVar}(?=\s*=)" "${VarFile}" || true)
        for FoundVar in "${FoundVarList[@]}"; do
            run_script 'env_rename' "${FoundVar}" "${ToVar}" "${VarFile}"
            if [[ ${VarFile} == "${COMPOSE_ENV}" ]] && ! run_script 'env_var_exists' "${FoundVar}"; then
                # Renaming from the .env file and the variable was successfully renamed.
                # Rename the matching variable in the override file if needed
                run_script 'override_var_rename' "${FoundVar}" "${ToVar}"
            fi
        done
    else
        # Renaming variables in different files
        local -a FoundVarList=()
        readarray -t FoundVarList < <(grep -o -P "^\s*\K${FromVar}(?=\s*=)" "${FromVarFile}" || true)
        for FoundVar in "${FoundVarList[@]}"; do
            if [[ ${FromVarFile} == "${COMPOSE_ENV}" ]] && run_script 'override_var_exists' "${FoundVar}"; then
                # Variable exists in user's override file, copy instead of move
                run_script 'env_copy' "${FoundVar}" "${ToVar}" "${FromVarFile}" "${ToVarFile}"
            else
                run_script 'env_rename' "${FoundVar}" "${ToVar}" "${FromVarFile}" "${ToVarFile}"
            fi
        done
    fi
}

test_env_migrate() {
    # run_script 'env_migrate'
    warn "CI does not test env_migrate."
}
