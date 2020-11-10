#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_create() {
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        info "${SCRIPTPATH}/compose/.env found."
    else
        warn "${SCRIPTPATH}/compose/.env not found. Copying example template."
        cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp \"${SCRIPTPATH}/compose/.env.example\" \"${SCRIPTPATH}/compose/.env\""
        run_script 'set_permissions' "${SCRIPTPATH}/compose/.env"
        run_script 'appvars_create' WATCHTOWER
    fi
    run_script 'env_sanitize'
}

test_env_create() {
    run_script 'env_create'
    cat "${SCRIPTPATH}/compose/.env"
}
