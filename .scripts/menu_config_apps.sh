#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    Title="Edit Application Variables"

    local AddedApps
    AddedApps=$(run_script 'app_list_referenced')
    if [[ -z ${AddedApps} ]]; then
        dialog --title "${DC["TitleError"]}${Title}" --msgbox "There are no apps added to configure." 0 0
        return
    fi
    AddedApps=$(run_script 'app_nicename' "${AddedApps}")
    local -a AppOptions
    for AppName in ${AddedApps}; do
        local AppDescription
        AppDescription=$(run_script 'app_description' "${AppName}")
        AppOptions+=("${AppName}" "${AppDescription}")
    done
    local ListRows=$((${#AppOptions[@]} / 2))
    local LastAppChoice=""
    while true; do
        local MenuText="Select the application to configure"
        local -i ScreenRows ScreenCols ScreenHelplineRows
        local -i WindowRowsMax WindowColsMax
        local -i WindowRows WindowCols WindowListRows WindowListRowsMax
        local -i WindowButtonRows MenuTextRows
        ScreenRows="${LINES}"
        ScreenCols="${COLUMNS}"
        WindowRowsMax=$((ScreenRows - DC["WindowHeightAdjust"]))
        WindowColsMax=$((ScreenCols - DC["WindowWidthAdjust"]))
        local -a AppChoiceParams=(
            --stdout
        )
        MenuTextRows="$(dialog "${AppChoiceParams[@]}" --print-text-size "${MenuText}" "${WindowRowsMax}" "${WindowColsMax}" | cut -d ' ' -f 1)"
        ListRowsMax=$((WindowRowsMax - MenuTextRows - DC["TextHightAdjust"]))
        dialog --msgbox "WindowRowsMax=${WindowRowsMax}\nMenuTextRows=${MenuTextRows}\nDC["TextHightAdjust"]=${DC["TextHightAdjust"]}ListRowsMax=${ListRowsMax}" 0 0
        if [[ ${ListRows} -lt ${ListRowsMax} ]]; then
            WindowRows=0
            WindowListRows=-0
        else
            WindowRows="${WindowRowsMax}"
            WindowListRows=-1
        fi
        WindowCols="${WindowColsMax}"
        local -a AppChoiceDialog=(
            "${AppChoiceParams[@]}"
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Done"
            --menu "${MenuText}"
            "${WindowRows}" "${WindowCols}"
            "${WindowListRows}"
            "${AppOptions[@]}"
        )
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
