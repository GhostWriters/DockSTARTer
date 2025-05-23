#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    notice "Enter appvars_create_all"
    notice "appvars_create_all -> env_create"
    run_script 'env_create'
    notice "env_create -> appvars_create_all"
    run_script 'appvars_migrate_enabled_lines'
    local AddedApps
    AddedApps=$(run_script 'app_list_added')
    if [[ -n ${AddedApps-} ]]; then
        notice "Creating environment variables for added apps. Please be patient, this can take a while."
        run_script 'appvars_create' "${AddedApps}"
    else
        notice "${COMPOSE_ENV} does not contain any added apps."
    fi
    run_script 'env_update'
    notice "Exit appvars_create_all"
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    cat "${COMPOSE_ENV}"
}
