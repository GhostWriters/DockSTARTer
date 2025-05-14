#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_global_var() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")
    local Title="Add Application Variable"
    dialog --colors --title "${Title}" --msgbox "Add a variable for ${AppName}" 0 0
}

test_menu_add_global_var() {
    # run_script 'menu_add_global_var'
    warn "CI does not test menu_add_global_var."
}
