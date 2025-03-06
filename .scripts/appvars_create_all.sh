#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    local INSTALLED_APPS
    run_script 'appvars_migrate_enabled_lines'
    INSTALLED_APPS=$(run_script 'app_list_installed')
    if [[ -n ${INSTALLED_APPS-} ]]; then
        notice "Creating environment variables for installed apps. Please be patient, this can take a while."
        run_script 'appvars_create' "${INSTALLED_APPS}"
    else
        notice "${COMPOSE_ENV} does not contain any installed apps."
    fi
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
