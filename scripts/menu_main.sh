#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTIONS
    MAINOPTIONS=()
    MAINOPTIONS+=("Configure Apps" "Setup and start applications")
    MAINOPTIONS+=("Install Dependencies" "Latest version of Docker and Docker-Compose")
    MAINOPTIONS+=("Update DockSTARTer" "Get the latest version of DockSTARTer")
    MAINOPTIONS+=("Prune Docker System" "Remove all unused containers, networks, volumes, images and build cache")

    local MAINCHOICE
    MAINCHOICE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like to do?" --cancel-button "Exit" 0 0 0 "${MAINOPTIONS[@]}" 3>&1 1>&2 2>&3)

    case "${MAINCHOICE}" in
        "Configure Apps")
            run_script 'ui_config' || run_script 'menu_main'
            ;;
        "Install Dependencies")
            run_script 'ui_install' || run_script 'menu_main'
            ;;
        "Update DockSTARTer")
            run_script 'update_self' menu || run_script 'menu_main'
            ;;
        "Prune Docker System")
            run_script 'prune_docker' menu || run_script 'menu_main'
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}
