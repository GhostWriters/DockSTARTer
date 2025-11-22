#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options_theme() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Choose Theme"

    run_script 'config_theme'

    local CurrentTheme
    CurrentTheme="$(run_script 'theme_name')"

    local -a ThemeList
    local -A ThemeDescription ThemeAuthor
    readarray -t ThemeList < <(run_script 'theme_list')
    for ThemeName in "${ThemeList[@]-}"; do
        ThemeDescription["${ThemeName}"]="$(run_script 'theme_description' "${ThemeName}")"
        ThemeAuthor["${ThemeName}"]="$(run_script 'theme_author' "${ThemeName}")"
    done

    local LastChoice="${CurrentTheme}"
    while true; do
        local -a Opts=()
        for ThemeName in "${ThemeList[@]-}"; do
            local ItemText="${ThemeDescription["${ThemeName}"]}"
            if [[ -n ${ThemeAuthor["${ThemeName}"]} ]]; then
                ItemText+=" [by ${ThemeAuthor["${ThemeName}"]}]"
            fi
            if [[ ${ThemeName} == "${CurrentTheme}" ]]; then
                Opts+=("${ThemeName}" "${DC["ListApp"]-}${ItemText}" ON)
            else
                Opts+=("${ThemeName}" "${DC["ListApp"]-}${ItemText}" OFF)
            fi
        done
        local -a ChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]-}${Title}"
            --ok-label "Select"
            --cancel-label "Back"
            --radiolist "Select the theme to apply." 0 0 0
            "${Opts[@]}"
        )
        local Choice
        local -i DialogButtonPressed=0
        Choice=$(_dialog_ --default-item "${LastChoice}" "${ChoiceDialog[@]}") || DialogButtonPressed=$?
        LastChoice=${Choice}
        case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
            OK)
                CurrentTheme="${Choice}"
                if run_script 'config_theme' "${CurrentTheme}"; then
                    run_script 'menu_dialog_example' "Applied theme ${CurrentTheme}" "${APPLICATION_COMMAND} --theme \"${CurrentTheme}\""
                else
                    dialog_error "${Title}" "Unable to apply theme ${CurrentTheme}"
                fi
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[DialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${F[C]}${DIALOG_BUTTONS[DialogButtonPressed]}${NC}' pressed in '${C["RunningCommand"]-}${FUNCNAME[0]}${NC}'."
                else
                    fatal "Unexpected dialog button value '${F[C]}${DialogButtonPressed}' pressed in '${C["RunningCommand"]-}${FUNCNAME[0]}${NC}'."
                fi
                ;;
        esac
    done
}

test_menu_options_theme() {
    warn "CI does not test menu_options_theme."
}
