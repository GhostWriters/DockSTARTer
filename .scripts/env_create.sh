#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_create() {
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        info "${SCRIPTPATH}/compose/.env found."
    else
        warning "${SCRIPTPATH}/compose/.env not found. Copying example template."
        cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "${SCRIPTPATH}/compose/.env could not be copied."
        run_script 'set_permissions' "${SCRIPTPATH}/compose/.env"
    fi
    run_script 'env_sanitize'
}

test_env_create() {
    run_script 'env_create'
}
