#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_rename() {
    local FROMVAR=${1-}
    local TOVAR=${2-}
    local VAR_FILE=${3:-$COMPOSE_ENV}
    if grep -q -P "^\s*${FROMVAR}\s*=" "${VAR_FILE}"; then
        notice "Renaming ${FROMVAR} to ${TOVAR} in ${VAR_FILE} file."
        sed -i "s/^\s*${FROMVAR}\s*=/${TOVAR}=/" "${VAR_FILE}" || fatal "Failed to rename var from ${FROMVAR} to ${TOVAR} in ${VAR_FILE}\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROMVAR}\\s*=/${TOVAR}=/\" \"${VAR_FILE}\""
    fi
}

test_env_rename() {
    # run_script 'env_rename'
    warn "CI does not test env_rename."
}
