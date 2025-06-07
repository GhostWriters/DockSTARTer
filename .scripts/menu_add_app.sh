#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_app() {
    local Title="Add Application"
    dialog_error "${Title}" "Add Application is not implemented yet."
    #local AppName BaseAppName InstanceName
}
test_menu_add_app() {
    # run_script 'menu_add_var'
    warn "CI does not test menu_add_app."
}
