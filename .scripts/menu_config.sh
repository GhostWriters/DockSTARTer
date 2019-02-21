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
            run_script 'config_vpn' "${INTERFACE:-false}"
            run_script 'config_global' "${INTERFACE:-false}"
            run_script 'generate_yml'
            run_script 'run_compose' "${INTERFACE:-false}"
            ;;
        "Select Apps ")
            run_script 'env_update'
            run_script 'menu_app_select'
            run_script 'generate_yml'
            run_script 'run_compose' "${INTERFACE:-false}"
            ;;
        "Set App Variables ")
            run_script 'env_update'
            run_script 'config_apps'
            run_script 'generate_yml'
            run_script 'run_compose' "${INTERFACE:-false}"
            ;;
        "Set VPN Variables ")
            run_script 'env_update'
            run_script 'config_vpn' "${INTERFACE:-false}"
            run_script 'generate_yml'
            run_script 'run_compose' "${INTERFACE:-false}"
            ;;
        "Set Global Variables ")
            run_script 'env_update'
            run_script 'config_global' "${INTERFACE:-false}"
            run_script 'generate_yml'
            run_script 'run_compose' "${INTERFACE:-false}"
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
