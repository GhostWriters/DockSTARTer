#!/usr/bin/env bash
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
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        CONFIGCHOICE="Cancel"
    else
        CONFIGCHOICE=$(whiptail --fb --clear --title "DockSTARTer" --menu "What would you like to do?" 0 0 0 "${CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${CONFIGCHOICE}" in
        "Full Setup ")
            run_script 'env_update'
            run_script 'menu_app_select'
            run_script 'config_apps'
            run_script 'config_vpn'
            run_script 'config_global'
            run_script 'generate_yml'
            run_script 'run_compose'
            ;;
        "Select Apps ")
            run_script 'env_update'
            run_script 'menu_app_select'
            run_script 'generate_yml'
            run_script 'run_compose'
            ;;
        "Set App Variables ")
            run_script 'env_update'
            run_script 'config_apps'
            run_script 'generate_yml'
            run_script 'run_compose'
            ;;
        "Set VPN Variables ")
            run_script 'env_update'
            run_script 'config_vpn'
            run_script 'generate_yml'
            run_script 'run_compose'
            ;;
        "Set Global Variables ")
            run_script 'env_update'
            run_script 'config_global'
            run_script 'generate_yml'
            run_script 'run_compose'
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}

test_menu_config() {
    # run_script 'menu_config'
    warning "Travis does not test menu_config."
}
