#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_apps() {
    info "Configuring .env variables for enabled apps."
    run_script 'appvars_create_all'
    while IFS= read -r APPNAME; do
        run_script 'menu_app_vars' "${APPNAME}" || return 1
    done < <(run_script 'app_list_enabled')
}

test_config_apps() {
    # run_script 'config_apps'
    warn "CI does not test config_apps."
}
