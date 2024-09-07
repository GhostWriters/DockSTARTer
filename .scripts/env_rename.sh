#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_rename() {
    local FROMVAR=${1-}
    local TOVAR=${2-}
    if grep -q -P "^\s*${FROMVAR}\s*=" "${COMPOSE_ENV}"; then
        notice "Renaming ${FROMVAR} to ${TOVAR} in ${COMPOSE_ENV} file."
        sed -i "s/^\s*${FROMVAR}\s*=/${TOVAR}=/" "${COMPOSE_ENV}" || fatal "Failed to rename var from ${FROMVAR} to ${TOVAR}\nFailing command: ${F[C]}sed -i \"s/^\\s*${FROMVAR}\\s*=/${TOVAR}=/\" \"${COMPOSE_ENV}\""
    fi
}

test_env_rename() {
    # run_script 'env_rename'
    warn "CI does not test env_rename."
}
