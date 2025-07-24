#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_create_all() {
    run_script 'env_create'
    run_script 'appvars_migrate_enabled_lines'
    local AddedApps
    AddedApps="$(run_script 'app_list_added')"
    if [[ -n ${AddedApps-} ]]; then
        notice "Creating environment variables for added apps. Please be patient, this can take a while."
        run_script 'appvars_create' "${AddedApps}"
    else
        notice "${C["File"]}${COMPOSE_ENV}${NC} does not contain any added apps."
    fi
    run_script 'env_update'
}

test_appvars_create_all() {
    run_script 'appvars_create_all'
    cat "${COMPOSE_ENV}"
}
