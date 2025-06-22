#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_display_options_theme() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Choose Theme"

    run_script 'apply_theme'

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
                Opts+=("${ThemeName}" "${ItemText}" ON)
            else
                Opts+=("${ThemeName}" "${ItemText}" OFF)
            fi
        done
        local -a ChoiceDialog=(
            --stdout
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Back"
            --radiolist "Select the theme to apply." 0 0 0
            "${Opts[@]}"
        )
        local Choice
        local -i DialogButtonPressed=0
        Choice=$(dialog --default-item "${LastChoice}" "${ChoiceDialog[@]}") || DialogButtonPressed=$?
        LastChoice=${Choice}
        case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
            OK)
                CurrentTheme="${Choice}"
                run_script 'apply_theme' "${CurrentTheme}"
                run_script 'menu_dialog_example' "Applied theme ${CurrentTheme}" "ds --theme \"${CurrentTheme}\""
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[DialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[DialogButtonPressed]}' pressed in menu_display_options_theme."
                else
                    fatal "Unexpected dialog button value '${DialogButtonPressed}' pressed in menu_display_options_theme."
                fi
                ;;
        esac
    done
}

test_menu_display_options_theme() {
    warn "CI does not test menu_display_options_theme."
}
