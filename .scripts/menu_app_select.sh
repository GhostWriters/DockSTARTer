#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Applications"
    dialog --title "${DC["Title"]}${Title}" --infobox "Preparing app menu. Please be patient, this can take a while." 0 0
    local -a AppList=()
    local -a AddedApps=()
    readarray -t AllApps < <((
        run_script 'app_list_added'
        run_script 'app_list_nondepreciated'
    ) | tr '[:upper:]' '[:lower:]' | sort -u)
    for APPNAME in "${AllApps[@]-}"; do
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
                if run_script 'app_is_added' "${APPNAME}"; then
                    AppOnOff="on"
                    AddedApps+=("${AppName}")
                else
                    AppOnOff="off"
                fi
                AppList+=("${AppName}" "${AppDescription}" "${AppOnOff}")
            fi
        fi
    done

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
            local AppsToAdd AppsToRemove
            AppsToRemove=$(printf '%s\n' "${AddedApps[@]}" "${SelectedApps[@]}" "${SelectedApps[@]}" | tr ' ' '\n' | sort -f | uniq -u)
            AppsToAdd=$(printf '%s\n' "${AddedApps[@]}" "${AddedApps[@]}" "${SelectedApps[@]}" | tr ' ' '\n' | sort -f | uniq -u)
            local Heading=''
            local HeadingRemove
            local HeadingAdd
            if [[ -n ${AppsToAdd-} || -n ${AppsToRemove-} ]]; then
                if [[ -n ${AppsToAdd-} ]]; then
                    local FormattedAppList
                    local HeadingAddCommand=' ds --add    '
                    local Indent='             '
                    FormattedAppList="$(printf "${Indent}%s\n" "$(highlighted_list "${AppsToAdd}")" | fmt -w "${COLUMNS}")"
                    HeadingAdd="\n${DC[NC]}${HeadingAddCommand}${FormattedAppList:${#Indent}}\n"
                fi
                if [[ -n ${AppsToRemove-} ]]; then
                    local HeadingRemoveCommand=' ds --remove '
                    local Indent='             '
                    FormattedAppList="$(printf "${Indent}%s\n" "$(highlighted_list "${AppsToRemove}")" | fmt -w "${COLUMNS}")"
                    HeadingRemove="\n${DC[NC]}${HeadingRemoveCommand}${FormattedAppList:${#Indent}}\n"
                fi
                Heading="${HeadingAdd-}${HeadingRemove-}"
                {
                    run_script 'env_backup'
                    if [[ -n ${AppsToAdd-} ]]; then
                        notice "Creating variables for selected apps."
                        run_script 'appvars_create' "${AppsToAdd}"
                    fi
                    if [[ -n ${AppsToRemove-} ]]; then
                        notice "Removing variables for deselected apps."
                        run_script 'appvars_purge' "${AppsToRemove}"
                    fi
                    notice "Updating variable files"
                    run_script 'env_sanitize'
                    run_script 'env_update'
                } |& dialog_pipe "${DC["TitleSuccess"]}Enabling Selected Applications" "${Heading}" "${DIALOGTIMEOUT}"
            fi
            return 0
            ;;
        CANCEL | ESC)
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} ]]; then
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]}' pressed in menu_app_select."
            else
                fatal "Unexpected dialog button value '${SelectedAppsDialogButtonPressed}' pressed in menu_app_select."
            fi
            ;;
    esac
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
