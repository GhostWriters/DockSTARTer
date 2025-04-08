#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Main Menu"
    local MainOpts=(
        "Configuration" "Setup and start applications"
        "Install Dependencies" "Install required components"
        "Update DockSTARTer" "Get the latest version of DockSTARTer"
        "Prune Docker System" "Remove all unused containers, networks, volumes, images and build cache"
    )
    local -a MainChoiceDialog=(
        --stdout
        --title "${Title}"
        --cancel-button "Exit"
        --menu "What would you like to do?" 0 0 0
        "${MainOpts[@]}"
    )

    local LastMainChoice=""
    while true; do
        local MainChoice
        local -i MainDialogButtonPressed=0
        MainChoice=$(dialog --default-item "${LastMainChoice}" "${MainChoiceDialog[@]}") || MainDialogButtonPressed=$?
        LastMainChoice=${MainChoice}
        case ${MainDialogButtonPressed} in
            ${DIALOG_OK})
                case "${MainChoice}" in
                    "Configuration")
                        run_script 'menu_config' || true
                        ;;
                    "Install Dependencies")
                        run_script 'run_install' || true
                        ;;
                    "Update DockSTARTer")
                        run_script 'update_self' || true
                        ;;
                    "Prune Docker System")
                        run_script 'docker_prune' || true
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            ${DIALOG_CANCEL} | ${DIALOG_ESC})
                clear
                info "Exiting DockSTARTer."
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[$MainDialogButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[$MainDialogButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value'${MainDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_main() {
    # run_script 'menu_main'
    warn "CI does not test menu_main."
}
