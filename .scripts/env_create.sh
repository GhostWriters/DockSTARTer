#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_create() {
    if [[ -f ${COMPOSE_ENV} ]]; then
        info "${COMPOSE_ENV} found."
    else
        warn "${COMPOSE_ENV} not found. Copying example template."
        cp "${COMPOSE_ENV}.example" "${COMPOSE_ENV}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${COMPOSE_ENV}.example\" \"${COMPOSE_ENV}\""
        run_script 'set_permissions' "${COMPOSE_ENV}"
        run_script 'appvars_create' WATCHTOWER
    fi
    run_script 'env_sanitize'
}

test_env_create() {
    run_script 'env_create'
    cat "${COMPOSE_ENV}"
}
