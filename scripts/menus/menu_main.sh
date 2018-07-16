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
            "Install/Reconfigure" "Setup and start applications" \
            "Install/Update Dependencies" "Latest version of Docker and Docker-Compose" \
            "Update DockStarter" "Get the latest version of DockSTARTer" 3>&1 1>&2 2>&3)

    local EXITSTATUS
    EXITSTATUS=${?}
    if [[ ${EXITSTATUS} == 0 ]]; then
        case "${MAINCHOICE}" in
            "Install/Reconfigure" )
                run_menu 'application_selector'
                run_menu 'timezone_set'
                run_menu 'user_group_set'
                run_menu 'config_folder_set'
                run_menu 'download_folder_set'
                run_menu 'media_folders_set'
                run_script 'generate_yml'
                run_script 'run_compose' menu
                ;;
            "Install/Update Dependencies" )
                run_script 'run_apt'
                run_script 'install_yq' force
                run_script 'install_docker' force
                run_script 'install_machine_completion'
                run_script 'install_compose' force
                run_script 'install_compose_completion'
                run_script 'setup_docker_group'
                run_script 'enable_docker_systemd'
                run_script 'request_reboot' menu
                ;;
            "Update DockStarter" )
                run_script 'update_self' menu
                run_script 'run_apt'
                run_script 'install_yq' force
                run_script 'install_docker' force
                run_script 'install_machine_completion'
                run_script 'install_compose' force
                run_script 'install_compose_completion'
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
