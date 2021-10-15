#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    if grep -q '_ENABLED=true$' "${SCRIPTPATH}/compose/.env"; then
        notice "Creating environment variables for enabled apps. Please be patient, this can take a while."
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=true}
            run_script 'appvars_create' "${APPNAME}"
            info "Environment variables created for ${APPNAME}."
        done < <(grep '_ENABLED=true$' "${SCRIPTPATH}/compose/.env")
    else
        notice "${SCRIPTPATH}/compose/.env does not contain any enabled apps."
    fi
}

test_appvars_create_all() {
    run_script 'env_update'
    run_script 'appvars_create_all'
    cat "${SCRIPTPATH}/compose/.env"
}
