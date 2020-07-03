#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

config_apps() {
    info "Configuring .env variables for enabled apps."
    run_script 'appvars_create_all'
    while IFS= read -r line; do
        local APPNAME=${line%%_ENABLED=true}
        run_script 'menu_app_vars' "${APPNAME}" || return 1
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
}

test_config_apps() {
    # run_script 'config_apps'
    warn "CI does not test config_apps."
}
