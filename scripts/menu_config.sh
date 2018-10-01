#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

menu_config() {
    local CONFIGOPTS
    CONFIGOPTS=()
    CONFIGOPTS+=("Full Setup " "")
    CONFIGOPTS+=("Select Apps " "")
    CONFIGOPTS+=("Set App Variables " "")
    CONFIGOPTS+=("Set VPN Variables " "")
    CONFIGOPTS+=("Set Global Variables " "")

    local CONFIGCHOICE
    CONFIGCHOICE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like to do?" 0 0 0 "${CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${CONFIGCHOICE}" in
        "Full Setup ")
            run_script 'env_update' menu
            run_script 'menu_app_select' || run_script 'menu_config'
            run_script 'ui_config_apps' || run_script 'menu_config'
            run_script 'ui_config_vpn' || run_script 'menu_config'
            run_script 'ui_config_globals' || run_script 'menu_config'
            ;;
        "Select Apps ")
            run_script 'env_update' menu
            run_script 'menu_app_select' || run_script 'menu_config'
            ;;
        "Set App Variables ")
            run_script 'env_update' menu
            run_script 'ui_config_apps' || run_script 'menu_config'
            ;;
        "Set VPN Variables ")
            run_script 'env_update' menu
            run_script 'ui_config_vpn' || run_script 'menu_config'
            ;;
        "Set Global Variables ")
            run_script 'env_update' menu
            run_script 'ui_config_globals' || run_script 'menu_config'
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac

    run_script 'generate_yml' || return 1
    run_script 'run_compose' menu || return 1
}
