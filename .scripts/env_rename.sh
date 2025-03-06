#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_rename() {
    local FROM_VAR=${1-}
    local TO_VAR=${2-}
    local VAR_FILE=${3:-$COMPOSE_ENV}

    if [[ -f ${VAR_FILE} ]]; then
        # Variable file does not exist, warn and return
        warn "File ${VAR_FILE} does not exist."
        return
    fi
    if [[ ${FROM_VAR_FILE} == "${TO_VAR_FILE}" ]]; then
        # Trying to rename to the same name, do nothing
        return
    fi
    if grep -q -P "^\s*\K${TO_VAR}(?=\s*=)" "${VAR_FILE}"; then
        # Variable to rename to already exists, do nothing
        return
    fi

    notice "Renaming ${FOUND_VAR} to ${TO_VAR} in ${VAR_FILE}"
    sed -i "s/^\s*${FROM_VAR}\s*=/${TO_VAR}=/g" "${VAR_FILE}" ||
        fatal "Failed to rename var from ${FROM_VAR} to ${TO_VAR} in ${VAR_FILE}\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROM_VAR}\\s*=/${TO_VAR}=/g\" \"${VAR_FILE}\""
}

test_env_rename() {
    # run_script 'env_rename'
    warn "CI does not test env_rename."
}
