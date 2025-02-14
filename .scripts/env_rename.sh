#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_rename() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local FROM_VAR_FILE=${3:-$COMPOSE_ENV}
    local TO_VAR_FILE=${4:-$COMPOSE_ENV}

    # Change the .env file to use if specified in the variable, and remove the appname from the string
    if [[ ${TO_VAR} == *":"* ]]; then
        TO_VAR_FILE="${APP_ENV_FOLDER}/${TO_VAR%:*}.env"
        TO_VAR="${TO_VAR#*:}"
    fi
    if [[ ${FROM_VAR} == *":"* ]]; then
        FROM_VAR_FILE="${APP_ENV_FOLDER}/${FROM_VAR%:*}.env"
        FROM_VAR="${FROM_VAR#*:}"
    fi

    if [[ ${FROM_VAR_FILE-} == "${TO_VAR_FILE-}" ]]; then
        # Renaming variables in the same file, do a replace
        local VAR_FILE=${FROM_VAR_FILE}
        if grep -q -P "^\s*${FROM_VAR}\s*=" "${VAR_FILE}"; then
            notice "Renaming ${FROM_VAR} to ${TO_VAR} in ${VAR_FILE}"
            sed -i "s/^\s*${FROM_VAR}\s*=/${TO_VAR}=/" "${VAR_FILE}" || fatal "Failed to rename var from ${FROM_VAR} to ${TO_VAR} in ${VAR_FILE}\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROM_VAR}\\s*=/${TO_VAR}=/\" \"${VAR_FILE}\""
        fi
    else
        # Renaming variables in different files, do a copy and delete
        if grep -q -P "^\s*${FROM_VAR}\s*=" "${FROM_VAR_FILE}"; then
            notice "Moving ${FROM_VAR} in ${FROM_VAR_FILE} to:\n ${TO_VAR} in ${TO_VAR_FILE}"
            #sed -i "s/^\s*${FROM_VAR}\s*=/${TO_VAR}=/" "${VAR_FILE}" || fatal "Failed to rename var from ${FROM_VAR} to ${TO_VAR} in ${VAR_FILE}\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROM_VAR}\\s*=/${TO_VAR}=/\" \"${VAR_FILE}\""
        fi
    fi
}

test_env_rename() {
    # run_script 'env_rename'
    warn "CI does not test env_rename."
}
