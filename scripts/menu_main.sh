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

    local MAINOPTIONS
    MAINOPTIONS=()
    MAINOPTIONS+=("Configure Apps" "Setup and start applications")
    MAINOPTIONS+=("Install Dependencies" "Latest version of Docker and Docker-Compose")
    MAINOPTIONS+=("Update DockSTARTer" "Get the latest version of DockSTARTer")
    MAINOPTIONS+=("Prune Docker System" "Remove all unused containers, networks, volumes, images and build cache")

    local MAINCHOICE
    MAINCHOICE=$(whiptail --fb --title "DockSTARTer" --menu "What would you like to do?" --cancel-button "Exit" ${LINES} ${COLUMNS} ${NETLINES} "${MAINOPTIONS[@]}" 3>&1 1>&2 2>&3)
    reset || true

    case "${MAINCHOICE}" in
        "Configure Apps")
            run_script 'ui_config'
            ;;
        "Install Dependencies")
            run_script 'ui_install'
            ;;
        "Update DockSTARTer")
            run_script 'ui_update'
            ;;
        "Prune Docker System")
            run_script 'prune_docker' menu
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}
