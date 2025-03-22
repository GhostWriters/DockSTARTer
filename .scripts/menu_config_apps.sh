#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    info "Configuring .env variables for enabled apps."
    run_script 'appvars_create_all'
    local AddedApps
    AddedApps=$(run_script 'app_list_added')
    AddedApps=$(run_script 'app_nicename' "${AddedApps}")
    dialog --clear --msgbox "AddedApps=[${AddedApps}]" 0 0
    if [[ -z ${AddedApps} ]]; then
        dialog --msgbox "There are no apps added."
        return
    fi
    local -a AppOptions
    for AppName in ${AddedApps}; do
        local AppDescription
        AppDescription=$(run_script 'app_description' "${AppName}")
        AppOptions+=("${AppName}" "${AppDescription}")
    done
    local -a AppChoiceDialog
    AppChoiceDialog=(
        --clear
        --stdout
        --title "Set App Variables"
        --cancel-button "Exit"
        --menu "Select the application to configure" 0 0 0
        "${AppOptions[@]}"
    )
    while true; do
        local AppChoice
        local AppChoiceButtonPressed=0
        AppChoice=$(dialog "${AppChoiceDialog[@]}") || AppChoiceButtonPressed=$?
        case ${AppChoiceButtonPressed} in
            "${DIALOG_OK}")
                run_script 'menu_app_vars' "${AppChoice}"
                ;;
            "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[$AppChoiceButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[$AppChoiceButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value'${AppChoiceButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_config_apps() {
    # run_script 'menu_config_apps'
    warn "CI does not test menu_config_apps."
}
