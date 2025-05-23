#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    Title="Edit Application Variables"

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
                run_script 'menu_config_vars' "${AppChoice}"
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
