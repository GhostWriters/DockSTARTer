#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_create() {
    if [[ -f ${SCRIPTPATH}/compose/.env ]]; then
        info "${SCRIPTPATH}/compose/.env found."
    else
        warning "${SCRIPTPATH}/compose/.env not found. Copying example template."
        run_cmd cp "${SCRIPTPATH}/compose/.env.example" "${SCRIPTPATH}/compose/.env" || fatal "${SCRIPTPATH}/compose/.env could not be copied."
    fi
    run_script 'env_sanitize'
}
