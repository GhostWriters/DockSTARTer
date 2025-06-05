#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_app() {
    local Title="Add Application"
    dialog --title "${Title}" --msgbox "Add Variable is not implemented yet." 0 0 || true
}
test_menu_add_app() {
    # run_script 'menu_add_var'
    warn "CI does not test menu_add_var."
}
