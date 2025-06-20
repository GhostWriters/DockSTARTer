#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Main Menu"
    local OptionConfigure="Configuration"
    local OptionInstallDependencies="Install Dependencies"
    local OptionUpdateVersion="Update DockSTARTer"
    local OptionDisplayOptions="Display Options"
    local MainOpts=(
        "${OptionConfigure}" "Setup and start applications"
        "${OptionInstallDependencies}" "Install required components"
        "${OptionUpdateVersion}" "Get the latest version of DockSTARTer"
        "${OptionDisplayOptions}" "Adjust display options for the GUI"
    )

    local LastMainChoice=""
    while true; do
        local -a MainChoiceDialog=(
            --stdout
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Exit"
            --menu "What would you like to do?" 0 0 0
            "${MainOpts[@]}"
        )
        local MainChoice
        local -i MainDialogButtonPressed=0
        MainChoice=$(dialog --default-item "${LastMainChoice}" "${MainChoiceDialog[@]}") || MainDialogButtonPressed=$?
        LastMainChoice=${MainChoice}
        case ${DIALOG_BUTTONS[MainDialogButtonPressed]-} in
            OK)
                case "${MainChoice}" in
                    "${OptionConfigure}")
                        run_script 'menu_config' || true
                        ;;
                    "${OptionInstallDependencies}")
                        run_script 'run_install' || true
                        ;;
                    "${OptionUpdateVersion}")
                        run_script 'update_self' || true
                        ;;
                    "${OptionDisplayOptions}")
                        run_script 'menu_display_options' || true
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            CANCEL | ESC)
                clear
                info "Exiting DockSTARTer."
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[MainDialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[MainDialogButtonPressed]}' pressed in menu_main."
                else
                    fatal "Unexpected dialog button value '${MainDialogButtonPressed}' pressed in menu_main."
                fi
                ;;
        esac
    done
}

test_menu_main() {
    # run_script 'menu_main'
    warn "CI does not test menu_main."
}
