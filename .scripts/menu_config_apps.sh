#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    local Title="Edit Application Variables"

    local LastAppChoice=""
    while true; do
        local AddedApps
        AddedApps=$(run_script 'app_list_referenced')
        if [[ -z ${AddedApps} ]]; then
            dialog --title "${DC["TitleError"]}${Title}" --msgbox "There are no apps added to configure." 0 0
            return
        fi
        AddedApps=$(run_script 'app_nicename' "${AddedApps}")
        local ScreenRows ScreenCols
        local WindowRowsMax WindowColsMax
        local WindowRows WindowCols WindowListRows
        local MenuTextSize MenuTextRows MenuTextCols
        #local ScreenSize
        #ScreenSize="$(dialog --stdout --print-maxsize)"
        #ScreenRows="$(echo "${ScreenSize}" | cut -d ' ' -f 2 | cut -d ',' -f 1)"
        #ScreenCols="$(echo "${ScreenSize}" | cut -d ' ' -f 3)"
        ScreenRows="${LINES}"
        ScreenCols="${COLUMNS}"
        WindowRowsMax=$((ScreenRows - DC["WindowRowsAdjust"]))
        WindowColsMax=$((ScreenCols - DC["WindowColsAdjust"]))

        local MenuText="Select the application to configure"
        local -a AppChoiceParams=(
            --stdout
        )
        local MenuTextSize
        MenuTextSize="$(dialog "${AppChoiceParams[@]}" --print-text-size "${MenuText}" "${WindowRowsMax}" "${WindowColsMax}")"
        MenuTextRows="$(echo "${MenuTextSize}" | cut -d ' ' -f 1)"
        MenuTextCols="$(echo "${MenuTextSize}" | cut -d ' ' -f 2)"
        local ListCols=${MenuTextCols}
        local -a AppOptions=()
        for AppName in ${AddedApps}; do
            local AppDescription
            AppDescription=$(run_script 'app_description' "${AppName}")
            AppOptions+=("${AppName}" "${AppDescription}")
            local CurrentListCols
            CurrentListCols=$((3 + "${#AppName}" + 2 + "${#AppDescription}" + 3))
            if [[ ${CurrentListCols} -gt ${ListCols} ]]; then
                ListCols=${CurrentListCols}
            fi
        done
        local ListRows=$((${#AppOptions[@]} / 2))

        WindowRows=$((MenuTextRows + ListRows + DC["TextRowsAdjust"]))
        if [[ ${WindowRows} -gt ${WindowRowsMax} ]]; then
            # More items than will fit on the screen, limit window size to the "Maximum" defined
            WindowRows="${WindowRowsMax}"
            WindowListRows=-1
        else
            # Fewer items than will fit on the screen, reduce the window size to fit
            WindowRows=0
            WindowListRows=0
        fi
        WindowCols=$((ListCols + DC["TextColsAdjust"]))
        WindowCols=$((WindowCols < WindowColsMax ? WindowCols : WindowColsMax))
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
