#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

config_apps() {
    info "Configuring .env variables for enabled apps."
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line%%_ENABLED=true}
        run_script 'menu_app_vars' "${APPNAME}" || return 1
    done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
}
