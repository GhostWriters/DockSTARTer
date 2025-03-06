#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_migrate() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
    local TO_VAR_FILE=${4:-$COMPOSE_ENV}

    # Change the .env file to use if specified in the variable, and remove the appname from the string
    # The file is specified as "appname:variable_name"
    if [[ ${FROM_VAR} == *":"* ]]; then
        FROM_VAR_FILE="${APP_ENV_FOLDER}/${FROM_VAR%:*}.env"
        FROM_VAR="${FROM_VAR#*:}"
    fi
    if [[ ${TO_VAR} == *":"* ]]; then
        TO_VAR_FILE="${APP_ENV_FOLDER}/${TO_VAR%:*}.env"
        TO_VAR="${TO_VAR#*:}"
    fi

    if [[ ! -f ${TO_VAR_FILE} ]]; then
        # Destination file does not exist, create it
        notice "Creating ${TO_VAR_FILE}"
        touch "${TO_VAR_FILE}"
    fi

    if grep -q -P "^\s*\K${TO_VAR}(?=\s*=)" "${TO_VAR_FILE}"; then
        # Variable to rename to already exists, do nothing
        return
    fi

    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
        # Renaming variables in the same file, do a rename
        local VAR_FILE=${FROM_VAR_FILE}
        local -a FOUND_VAR_LIST=()
        readarray -t FOUND_VAR_LIST < <(grep -o -P "^\s*\K${FROM_VAR}(?=\s*=)" "${VAR_FILE}" || true)
        for FOUND_VAR in "${FOUND_VAR_LIST[@]}"; do
            run_script 'env_rename' "${FOUND_VAR}" "${TO_VAR}" "${VAR_FILE}"
        done
    else
        # Renaming variables in different files, do a move
        local -a FOUND_VAR_LIST=()
        readarray -t FOUND_VAR_LIST < <(grep -o -P "^\s*\K${FROM_VAR}(?=\s*=)" "${FROM_VAR_FILE}" || true)
        for FOUND_VAR in "${FOUND_VAR_LIST[@]}"; do
            run_script 'env_move' "${FOUND_VAR}" "${TO_VAR}" "${FROM_VAR_FILE}" "${TO_VAR_FILE}"
        done
    fi
}

test_env_migrate() {
    # run_script 'env_migrate'
    warn "CI does not test env_migrate."
}
