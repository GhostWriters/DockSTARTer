#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    # Dialog color codes to be used in the GUI menu
    # shellcheck disable=SC2168 # local is only valid in functions
    local \
        ColorHeading \
        ColorHeadingValue \
        ColorHighlight
    # shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
    {
        ColorHeading='\Zr'
        ColorHeadingValue='\Zb\Zr'
        ColorHighlight='\Z3\Zb'
    }
    # shellcheck disable=SC2168 # local is only valid in functions
    local \
        ColorLineHeading \
        ColorLineComment \
        ColorLineOther \
        ColorLineVar \
        ColorLineAddVariable
    # shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
    {
        ColorLineHeading='\Zn'
        ColorLineComment='\Z0\Zb\Zr'
        ColorLineOther="${ColorLineComment}"
        ColorLineVar='\Z0\ZB\Zr'
        ColorLineAddVariable="${ColorLineVar}"
    }

    Title="Edit Application Variables"

    run_script_dialog "${Title}" "Setting up all applications" 1 \
        'appvars_create_all'
    local AddedApps
    AddedApps=$(run_script 'app_list_referenced')
    if [[ -z ${AddedApps} ]]; then
        dialog --title "{Title}" --msgbox "There are no apps added to configure." 0 0
        return
    fi
    AddedApps=$(run_script 'app_nicename' "${AddedApps}")
    local -a AppOptions
    for AppName in ${AddedApps}; do
        local AppDescription
        AppDescription=$(run_script 'app_description' "${AppName}")
        AppOptions+=("${AppName}" "${AppDescription}")
    done
    local -a AppChoiceDialog=(
        --stdout
        --title "${Title}"
        --ok-label "Select"
        --cancel-label "Done"
        --menu "Select the application to configure" 0 0 0
        "${AppOptions[@]}"
    )

    local LastAppChoice=""
    while true; do
        local AppChoice
        local -i AppChoiceButtonPressed=0
        AppChoice=$(dialog --default-item "${LastAppChoice}" "${AppChoiceDialog[@]}") || AppChoiceButtonPressed=$?
        LastAppChoice=${AppChoice}
        case ${DIALOG_BUTTONS[AppChoiceButtonPressed]-} in
            OK)
                run_script 'menu_app_vars' "${AppChoice}"
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[AppChoiceButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[AppChoiceButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value '${AppChoiceButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_config_apps() {
    # run_script 'menu_config_apps'
    warn "CI does not test menu_config_apps."
}
