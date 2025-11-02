#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
    local Title="Configure Applications"

    local AddAplicationText='<ADD APPLICATION>'

    local LastAppChoice=""
    while true; do
        local AddedApps
        AddedApps="$(run_script 'app_nicename' "$(run_script 'app_list_referenced')")"
        local ScreenRows ScreenCols
        local WindowRowsMax WindowColsMax
        local WindowRows WindowCols WindowListRows
        local MenuTextSize MenuTextRows MenuTextCols
        #local ScreenSize
        #ScreenSize="$(_dialog_ --output-fd 1 --print-maxsize)"
        #ScreenRows="$(echo "${ScreenSize}" | cut -d ' ' -f 2 | cut -d ',' -f 1)"
        #ScreenCols="$(echo "${ScreenSize}" | cut -d ' ' -f 3)"
        set_screen_size
        ScreenRows="${LINES}"
        ScreenCols="${COLUMNS}"
        WindowRowsMax=$((ScreenRows - DC["WindowRowsAdjust"]))
        WindowColsMax=$((ScreenCols - DC["WindowColsAdjust"]))

        local MenuText="Select the application to configure"
        local -a AppChoiceParams=(
            --output-fd 1
        )
        local MenuTextSize
        MenuTextSize="$(_dialog_ "${AppChoiceParams[@]}" --print-text-size "${MenuText}" "${WindowRowsMax}" "${WindowColsMax}")"
        MenuTextRows="$(echo "${MenuTextSize}" | cut -d ' ' -f 1)"
        MenuTextCols="$(echo "${MenuTextSize}" | cut -d ' ' -f 2)"
        local ListCols=${MenuTextCols}
        local -i TagCols=${#AddAplicationText}
        local -i ItemCols=0
        local -a AppOptions=()
        for AppName in ${AddedApps}; do
            local AppDescription
            AppDescription=$(run_script 'app_description' "${AppName}")
            if run_script 'app_is_user_defined' "${AppName}"; then
                AppOptions+=("${AppName}" "${DC["ListAppUserDefined"]-}${AppDescription}")
            else
                AppOptions+=("${AppName}" "${DC["ListApp"]}${AppDescription}")
            fi
            TagCols=$((${#AppName} > TagCols ? ${#AppName} : TagCols))
            ItemCols=$((${#AppDescription} > ItemCols ? ${#AppDescription} : ItemCols))
        done
        local ListCols=$((3 + TagCols + 2 + ItemCols + 3))
        ListCols=$((MenuTextCols > ListCols ? MenuTextCols : ListCols))
        AppOptions+=("${AddAplicationText}" "")
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
            --title "${DC["Title"]-}${Title}"
            --ok-label "Select"
            --cancel-label "Done"
            --menu "${MenuText}"
            "${WindowRows}" "${WindowCols}"
            "${WindowListRows}"
            "${AppOptions[@]}"
        )
        local AppChoice
        local -i AppChoiceButtonPressed=0
        AppChoice=$(_dialog_ --default-item "${LastAppChoice}" "${AppChoiceDialog[@]}") || AppChoiceButtonPressed=$?
        LastAppChoice=${AppChoice}
        case ${DIALOG_BUTTONS[AppChoiceButtonPressed]-} in
            OK)
                if [[ ${AppChoice} == "${AddAplicationText}" ]]; then
                    run_script 'menu_add_app'
                else
                    run_script 'menu_config_vars' "${AppChoice}"
                fi
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[AppChoiceButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[AppChoiceButtonPressed]}' pressed in menu_config_apps."
                else
                    fatal "Unexpected dialog button value '${AppChoiceButtonPressed}' pressed in menu_config_apps."
                fi
                ;;
        esac
    done
}

test_menu_config_apps() {
    # run_script 'menu_config_apps'
    warn "CI does not test menu_config_apps."
}
