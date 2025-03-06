#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    local AddedApps
    run_script 'appvars_migrate_enabled_lines'
    AddedApps=$(run_script 'app_list_added')
    if [[ -n ${AddedApps-} ]]; then
        notice "Creating environment variables for added apps. Please be patient, this can take a while."
        run_script 'appvars_create' "${AddedApps}"
    else
        notice "${COMPOSE_ENV} does not contain any added apps."
    fi
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    run_script 'env_update'
    cat "${COMPOSE_ENV}"
}
