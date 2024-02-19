#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

rename_var() {
    local FROMVAR=${1-}
    local TOVAR=${2-}
    notice "Renaming ${FROMVAR^^} to ${TOVAR^^} in ${COMPOSE_ENV} file."
    sed -i "s/^${FROMVAR^^}=/${TOVAR^^}=/" "${COMPOSE_ENV}" || fatal "Failed to rename var from ${FROMVAR^^} to ${TOVAR^^}\nFailing command: ${F[C]}sed -i \"s/^${FROMVAR^^}=/${TOVAR^^}=/\" \"${COMPOSE_ENV}\""
}

test_rename_var() {
    # run_script 'rename_var'
    warn "CI does not test rename_var."
}
