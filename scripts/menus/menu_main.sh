#!/bin/bash

menu_main() {
    LINES=14
    COLUMNS=80
    NETLINES=4

    readonly MAINCHOICE=$(whiptail --title "DockSTARTer" \
    --menu "What would you like to do?" --backtitle "$BACKTITLE" \
    --fb --cancel-button "Exit" $LINES $COLUMNS "$NETLINES" \
    "Install/reconfigure" "Setup and start applications" \
    "Install/Update" "Latest version of Docker and Docker-Compose" \
    "Update DockStarter" "Get the latest version of DockSTARTer" \
    "Update" "Host packages" 3>&1 1>&2 2>&3)

    EXITSTATUS=${?}
    if [[ $EXITSTATUS == 0 ]]; then
        case "$MAINCHOICE" in
            "Install/reconfigure" )
                run_script 'ui_controller' ;;
            "Install/Update" )
                #TODO
                echo -e "${RED}Currently not supported$ENDCOLOR" ;;
            "Update DockStarter" )
                #TODO
                echo -e "${RED}Currently not supported$ENDCOLOR" ;;
            "Update" )
                #TODO
                echo -e "${RED}Currently not supported$ENDCOLOR" ;;
            *)
                echo -e "${RED}Invalid Option$ENDCOLOR"
                ;; #TODO Exit safely
        esac
    else
        #TOD Thanks script
        echo
        sleep 1
        exit 0
    fi
}
