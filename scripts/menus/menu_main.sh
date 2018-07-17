#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local LINES
    LINES=$(stty size | cut '-d ' -f1)
    LINES=$((LINES<14?LINES:14))

    local COLUMNS
    COLUMNS=$(stty size | cut '-d ' -f2)
    COLUMNS=$((COLUMNS<70?COLUMNS:70))

    local NETLINES
    NETLINES=$((LINES<4?LINES:4))

    local MAINCHOICE
    MAINCHOICE=$(whiptail --title "DockSTARTer" \
            --menu "What would you like to do?" \
            --fb --cancel-button "Exit" \
            ${LINES} ${COLUMNS} ${NETLINES} \
            "Configure Apps" "Setup and start applications" \
            "Install Dependencies" "Latest version of Docker and Docker-Compose" \
        "Update DockStarter" "Get the latest version of DockSTARTer" 3>&1 1>&2 2>&3)

    case "${MAINCHOICE}" in
        "Configure Apps")
            run_script 'ui_config'
            ;;
        "Install Dependencies")
            run_script 'ui_install'
            ;;
        "Update DockStarter")
            run_script 'ui_update'
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}
