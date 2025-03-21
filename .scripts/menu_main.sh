#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
    local Title="Main Menu"
    local MainOpts=()
    MainOpts+=("Configuration" "Setup and start applications")
    MainOpts+=("Install Dependencies" "Install required components")
    MainOpts+=("Update DockSTARTer" "Get the latest version of DockSTARTer")
    MainOpts+=("Prune Docker System" "Remove all unused containers, networks, volumes, images and build cache")

    local DIALOG_BUTTON_PRESSED
    local MainChoice
    if [[ ${CI-} == true ]]; then
        DIALOG_BUTTON_PRESSED=${DIALOG_CANCEL}
    else
        local -a MainChoiceDialog=(
            --clear
            --stdout
            --title "${Title}"
            --cancel-button "Exit"
            --menu "What would you like to do?" 0 0 0
            "${MainOpts[@]}"
        )
        DIALOG_BUTTON_PRESSED=0 && MainChoice=$(dialog "${MainChoiceDialog[@]}") || DIALOG_BUTTON_PRESSED=$?
    fi
    case ${DIALOG_BUTTON_PRESSED} in
        "${DIALOG_OK}")
            case "${MainChoice}" in
                "Configuration")
                    clear
                    run_script 'menu_config' || run_script 'menu_main'
                    ;;
                "Install Dependencies")
                    clear
                    run_script 'run_install' || run_script 'menu_main'
                    ;;
                "Update DockSTARTer")
                    clear
                    run_script 'update_self' || run_script 'menu_main'
                    ;;
                "Prune Docker System")
                    clear
                    run_script 'docker_prune' || run_script 'menu_main'
                    ;;
                *)
                    clear
                    error "Invalid Option"
                    ;;
            esac
            ;;
        "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
            clear
            info "Exiting DockSTARTer."
            return
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]-} ]]; then
                clear
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]}' pressed."
            else
                clear
                fatal "Unexpected dialog button value'${DIALOG_BUTTON_PRESSED}' pressed."
            fi
            ;;
    esac

}

test_menu_main() {
    # run_script 'menu_main'
    warn "CI does not test menu_main."
}
