#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_config_apps() {
    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line/_ENABLED=true/}
        run_script 'menu_app_vars' "${APPNAME}" || return 1
    done < <(grep '_ENABLED=true' < "${SCRIPTPATH}/compose/.env")
}
