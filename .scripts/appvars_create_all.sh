#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    local ENABLED_APPS=$( run_script 'enabled_apps' )
    if [[ -n ${ENABLED_APPS-} ]]; then
        notice "Creating environment variables for enabled apps. Please be patient, this can take a while."
        for APPNAME in ${ENABLED_APPS}; do
            run_script 'appvars_create' "${APPNAME}"
            info "Environment variables created for ${APPNAME}."
        done
    else
        notice "${COMPOSE_ENV} does not contain any enabled apps."
    fi
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
