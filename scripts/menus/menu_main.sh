#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local LINES
    LINES=14
    local COLUMNS
    COLUMNS=80
    local NETLINES
    NETLINES=4

    local MAINCHOICE
    MAINCHOICE=$(whiptail --title "DockSTARTer" --menu \
            "What would you like to do?" --backtitle \
            "${BACKTITLE}" --fb --cancel-button \
            "Exit" ${LINES} ${COLUMNS} "${NETLINES}" \
            "Install/reconfigure" "Setup and start applications" \
            "Install/Update" "Latest version of Docker and Docker-Compose" \
            "Update DockStarter" "Get the latest version of DockSTARTer" \
            "Update" "Host packages" 3>&1 1>&2 2>&3)

    local EXITSTATUS
    EXITSTATUS=${?}
    if [[ ${EXITSTATUS} == 0 ]]; then
        case "${MAINCHOICE}" in
            "Install/reconfigure" )
                run_script 'ui_controller'
                ;;
            "Install/Update" )
                #TODO
                error "Currently not supported"
                ;;
            "Update DockStarter" )
                #TODO
                error "Currently not supported"
                ;;
            "Update" )
                #TODO
                error "Currently not supported"
                ;;
            *)
                error "Invalid Option"
                ;; #TODO Exit safely
        esac
    else
        #TODO Thanks script
        echo
        sleep 1
        exit 0
    fi
}
