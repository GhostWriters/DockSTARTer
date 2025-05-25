#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Applications"
    dialog --title "${DC["Title"]}${Title}" --infobox "Preparing app menu. Please be patient, this can take a while." 0 0
    local AppList=()
    local EnabledApps=()
    while IFS= read -r line; do
        local APPNAME=${line^^}
        local main_yml
        main_yml="$(run_script 'app_instance_file' "${APPNAME}" ".yml")"
        if [[ -f ${main_yml} ]]; then
            local main_yml
            arch_yml="$(run_script 'app_instance_file' "${APPNAME}" ".${ARCH}.yml")"
            if [[ -f ${arch_yml} ]]; then
                local AppName
                AppName=$(run_script 'app_nicename_from_template' "${APPNAME}")
                local AppDescription
                AppDescription=$(run_script 'app_description_from_template' "${APPNAME}")
                local AppOnOff
                if run_script 'app_is_enabled' "${APPNAME}"; then
                    AppOnOff="on"
                    EnabledApps+=("${AppName}")
                else
                    AppOnOff="off"
                fi
                AppList+=("${AppName}" "${AppDescription}" "${AppOnOff}")
            fi
        fi
    done < <(run_script 'app_list_nondepreciated')

    local -i SelectedAppsDialogButtonPressed
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
    else
        local SelectAppsDialogText="Choose which apps you would like to install:\n Use ${DC[RV]}[up]${DC[NC]}, ${DC[RV]}[down]${DC[NC]}, and ${DC[RV]}[space]${DC[NC]} to select apps, and ${DC[RV]}[tab]${DC[NC]} to switch to the buttons at the bottom."
        local SelectedAppsDialogParams=(
            --stdout
            --title "${DC["Title"]}${Title}"
        )
        local -i MenuTextLines
        MenuTextLines="$(dialog "${SelectedAppsDialogParams[@]}" --print-text-size "${SelectAppsDialogText}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" | cut -d ' ' -f 1)"
        local -a SelectedAppsDialog=(
            "${SelectedAppsDialogParams[@]}"
            --ok-label "Done"
            --cancel-label "Cancel"
            --separate-output
            --checklist
            "${SelectAppsDialogText}"
            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
            "$((LINES - DC["TextRowsAdjust"] - MenuTextLines))"
            "${AppList[@]}"
        )
        SelectedAppsDialogButtonPressed=0
        SelectedApps=$(dialog "${SelectedAppsDialog[@]}") || SelectedAppsDialogButtonPressed=$?
    fi
    case ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} in
        OK)
            local Heading=''
            if [[ -n ${EnabledApps[*]-} ]]; then
                local HeadingDisable=' ds --status-disable '
                local Indent='                     '
                FormattedAppList="$(printf "${Indent}%s\n" "$(highlighted_list "${EnabledApps[@]}")" | fmt -w "${COLUMNS}")"
                Heading+="\n${DC[NC]}${HeadingDisable}${FormattedAppList:"${#Indent}"}\n"
            fi
            if [[ -n ${SelectedApps-} ]]; then
                local FormattedAppList
                local HeadingEnable=' ds --status-enable  '
                local HeadingAdd=' ds --add            '
                local Indent='                     '
                FormattedAppList="$(printf "${Indent}%s\n" "$(highlighted_list "${SelectedApps}")" | fmt -w "${COLUMNS}")"
                Heading+="\n${DC[NC]}${HeadingEnable}${FormattedAppList:"${#Indent}"}\n"
                Heading+="\n${DC[NC]}${HeadingAdd}${FormattedAppList:"${#Indent}"}\n"
            fi
            local HeadingPurge=" ds --force --remove"
            Heading+="${DC[NC]}${HeadingPurge}"
            {
                if [[ -n ${EnabledApps[*]-} ]]; then
                    notice "Disabling previously selected apps."
                    run_script 'disable_app' "${EnabledApps[@]}"
                fi
                if [[ -n ${SelectedApps-} ]]; then
                    notice "Enabling selected apps."
                    run_script 'enable_app' "${SelectedApps}"
                    notice "Creating variables for selected apps."
                    run_script 'appvars_create' "${SelectedApps}"
                fi
                notice "Purging old variables"
                run_script 'appvars_purge_all'
                notice "Updating variable files"
                run_script 'env_update'
            } |& dialog_pipe "${DC["TitleSuccess"]}Enabling Selected Applications" "${Heading}" #"${DIALOGTIMEOUT}"
            return 0
            ;;
        CANCEL | ESC)
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} ]]; then
                clear
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]}' pressed."
            else
                clear
                fatal "Unexpected dialog button value '${SelectedAppsDialogButtonPressed}' pressed."
            fi
            ;;
    esac
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
