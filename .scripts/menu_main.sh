#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
    local BackTitle="DockSTARTer"
    local Title="Main Menu"
    local MainOpts=()
    MainOpts+=("Configuration " "Setup and start applications")
    MainOpts+=("Install Dependencies " "Install required components")
    MainOpts+=("Update DockSTARTer " "Get the latest version of DockSTARTer")
    MainOpts+=("Prune Docker System " "Remove all unused containers, networks, volumes, images and build cache")

    local MainChoice
    if [[ ${CI-} == true ]]; then
        MainChoice="Cancel"
    else
        local -a MainChoiceDialog=(
            --fb
            --clear
            --backtitle "${BackTitle}"
            --title "${Title}"
            --cancel-button "Exit"
            --menu "What would you like to do?" 0 0 0
            "${MainOpts[@]}"
        )
        MainChoice=$(dialog "${MainChoiceDialog[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        clear
    fi

    case "${MainChoice}" in
        "Configuration ")
            run_script 'menu_config' || run_script 'menu_main'
            ;;
        "Install Dependencies ")
            run_script 'run_install' || run_script 'menu_main'
            ;;
        "Update DockSTARTer ")
            run_script 'update_self' || run_script 'menu_main'
            ;;
        "Prune Docker System ")
            run_script 'docker_prune' || run_script 'menu_main'
            ;;
        "Cancel")
            info "Exiting DockSTARTer."
            return
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}

test_menu_main() {
    # run_script 'menu_main'
    warn "CI does not test menu_main."
}
