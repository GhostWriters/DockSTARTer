#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_global_var() {
    local Title="Add Global Variable"
    dialog --colors --title "${Title}" --msgbox "Add a global variable" 0 0
}

test_menu_add_global_var() {
    # run_script 'menu_add_global_var'
    warn "CI does not test menu_add_global_var."
}
