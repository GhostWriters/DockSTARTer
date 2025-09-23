#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Options"
    local Option_Theme="Choose Theme"
    local Option_Display="Display Options"
    local Opts=(
        "${Option_Theme}" "${DC["ListDefault"]}Choose a theme for ${APPLICATION_NAME}"
        "${Option_Display}" "${DC["ListDefault"]}Set display options"
    )

    local LastChoice=""
    while true; do
        local -a ChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]-}${Title}"
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
                    "${Option_Theme}")
                        run_script 'menu_options_theme' || true
                        ;;
                    "${Option_Display}")
                        run_script 'menu_options_display' || true
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
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[DialogButtonPressed]}' pressed in menu_options."
                else
                    fatal "Unexpected dialog button value '${DialogButtonPressed}' pressed in menu_options."
                fi
                ;;
        esac
    done
}

test_menu_options() {
    warn "CI does not test menu_options."
}
