#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    info "Configuring .env variables for enabled apps."
    run_script 'appvars_create_all'

    while IFS= read -r APPNAME; do
        run_script 'menu_app_vars' "${APPNAME}" || return 1
    done < <(run_script 'app_list_enabled')
}

test_menu_config_apps() {
    # run_script 'menu_config_apps'
    warn "CI does not test menu_config_apps."
}
