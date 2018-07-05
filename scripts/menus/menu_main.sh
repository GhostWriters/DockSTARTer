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
