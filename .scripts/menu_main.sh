#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Main Menu"
    local Option_Configure="Configuration"
    local Option_InstallDependencies="Install Dependencies"
    local Option_UpdateVersion="Update ${APPLICATION_NAME}"
    local Option_Options="Options"
    local MainOpts=(
        "${Option_Configure}" "${DC["ListDefault"]}Setup and start applications"
        "${Option_InstallDependencies}" "${DC["ListDefault"]}Install required components"
        "${Option_UpdateVersion}" "${DC["ListDefault"]}Get the latest version of ${APPLICATION_NAME}"
        "${Option_Options}" "${DC["ListDefault"]}Adjust options for ${APPLICATION_NAME}"
    )

    local LastMainChoice=""
    while true; do
        local -a MainChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]-}${Title}"
            --ok-label "Select"
            --cancel-label "Exit"
            --menu "What would you like to do?" 0 0 0
            "${MainOpts[@]}"
        )
        local MainChoice
        local -i MainDialogButtonPressed=0
        MainChoice=$(_dialog_ --default-item "${LastMainChoice}" "${MainChoiceDialog[@]}") || MainDialogButtonPressed=$?
        LastMainChoice=${MainChoice}
        case ${DIALOG_BUTTONS[MainDialogButtonPressed]-} in
            OK)
                case "${MainChoice}" in
                    "${Option_Configure}")
                        run_script 'menu_config' || true
                        ;;
                    "${Option_InstallDependencies}")
                        run_script 'run_install' || true
                        ;;
                    "${Option_UpdateVersion}")
                        run_script 'update_self' || true
                        ;;
                    "${Option_Options}")
                        run_script 'menu_options' || true
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            CANCEL | ESC)
                clear
                info "Exiting ${APPLICATION_NAME}."
                exit 0
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[MainDialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${F[C]}${DIALOG_BUTTONS[MainDialogButtonPressed]}${NC}' pressed in '${C["RunningCommand"]-}${FUNCNAME[0]}${NC}'."
                else
                    fatal "Unexpected dialog button value '${MainDialogButtonPressed}' pressed in '${C["RunningCommand"]-}${FUNCNAME[0]}${NC}'."
                fi
                ;;
        esac
    done
}

test_menu_main() {
    # run_script 'menu_main'
    warn "CI does not test menu_main."
}
