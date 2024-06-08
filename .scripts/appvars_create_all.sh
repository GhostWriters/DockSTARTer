#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    if grep -q -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}"; then
        notice "Creating environment variables for enabled apps. Please be patient, this can take a while."
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=*}
            run_script 'appvars_create' "${APPNAME}"
            info "Environment variables created for ${APPNAME}."
        done < <(grep --color=never -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}")
    else
        notice "${COMPOSE_ENV} does not contain any enabled apps."
    fi
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
