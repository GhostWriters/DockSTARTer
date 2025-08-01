#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_display_options() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Display Options"
    local OptionChooseTheme="Choose Theme"
    local OptionGeneralOptions="General Options"
    local Opts=(
        "${OptionChooseTheme}" "Choose a theme for ${APPLICATION_NAME}"
        "${OptionGeneralOptions}" "Set general display options"
    )

    local LastChoice=""
    while true; do
        local -a ChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Back"
            --menu "What would you like to do?" 0 0 0
            "${Opts[@]}"
        )
        local Choice
        local -i DialogButtonPressed=0
        Choice=$(_dialog_ --default-item "${LastChoice}" "${ChoiceDialog[@]}") || DialogButtonPressed=$?
        LastChoice=${Choice}
        case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
            OK)
                case "${Choice}" in
                    "${OptionChooseTheme}")
                        run_script 'menu_display_options_theme' || true
                        ;;
                    "${OptionGeneralOptions}")
                        run_script 'menu_display_options_general' || true
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            CANCEL | ESC)
                clear
                info "Exiting ${APPLICATION_NAME}."
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[DialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[DialogButtonPressed]}' pressed in menu_display_options."
                else
                    fatal "Unexpected dialog button value '${DialogButtonPressed}' pressed in menu_display_options."
                fi
                ;;
        esac
    done
}

test_menu_display_options() {
    warn "CI does not test menu_display_options."
}
