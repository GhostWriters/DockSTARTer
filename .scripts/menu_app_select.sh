#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Applications"

    local -a AppList AddedApps BuiltinApps
    local AddedAppsRegex=''

    readarray -t AddedApps < <(
        run_script 'app_list_added' |
            run_script 'app_filter_runnable_pipe' |
            tr '[:upper:]' '[:lower:]' |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null

    local MessageText="${DC["Subtitle"]}Preparing app menu. Please be patient, this can take a while.${DC[NC]}"
    dialog_info "${DC["TitleSuccess"]}${Title}" "${MessageText}"
    if [[ -n ${AddedApps[*]} ]]; then
        MessageText+="\n\nCurrently added applications:\n"
        MessageText+=$(printf '   %s\n' "${AddedApps[@]}")
        dialog_info "${DC["TitleSuccess"]}${Title}" "${MessageText}"
        {
            IFS='|'
            AddedAppsRegex="${AddedApps[*]}"
        }

    fi

    readarray -t BuiltinApps < <(
        run_script 'app_list_nondeprecated' |
            run_script 'app_filter_runnable_pipe'
    ) 2> /dev/null

    local -a AllApps
    readarray -t AllApps < <(
        printf '%s\n' "${AddedApps[@],,}" "${BuiltinApps[@],,}" |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null
    local LastAppLetter=''
    for AppName in "${AllApps[@]-}"; do
        local AppLetter=${AppName:0:1}
        AppLetter=${AppLetter^^}
        if [[ -n ${LastAppLetter-} && ${LastAppLetter} != "${AppLetter}" ]]; then
            AppList+=("" "" "off")
        fi
        LastAppLetter=${AppLetter}
        local AppDescription
        AppDescription=$(run_script 'app_description_from_template' "${AppName}")
        if [[ ${AppName} =~ ${AddedAppsRegex} ]]; then
            AppList+=("${AppName}" "${AppDescription}" "on")
        else
            AppList+=("${AppName}" "${AppDescription}" "off")
        fi
    done 2> /dev/null

    local -i SelectedAppsDialogButtonPressed
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
    else
        local SelectAppsDialogText="Choose which apps you would like to install:\n Use ${DC["KeyCap"]}[up]${DC[NC]}, ${DC["KeyCap"]}[down]${DC[NC]}, and ${DC["KeyCap"]}[space]${DC[NC]} to select apps, and ${DC["KeyCap"]}[tab]${DC[NC]} to switch to the buttons at the bottom."
        local SelectedAppsDialogParams=(
            --stdout
            --title "${DC["Title"]}${Title}"
        )
        local -i MenuTextLines
        MenuTextLines="$(_dialog_ "${SelectedAppsDialogParams[@]}" --print-text-size "${SelectAppsDialogText}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" | cut -d ' ' -f 1)"
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
        SelectedApps=$(_dialog_ "${SelectedAppsDialog[@]}") || SelectedAppsDialogButtonPressed=$?
    fi
    case ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} in
        OK)
            local AppsToAdd AppsToRemove
            AppsToRemove=$(printf '%s\n' "${AddedApps[@]}" "${SelectedApps[@]}" "${SelectedApps[@]}" | tr ' ' '\n' | sort -f | uniq -u | xargs)
            AppsToAdd=$(printf '%s\n' "${AddedApps[@]}" "${AddedApps[@]}" "${SelectedApps[@]}" | tr ' ' '\n' | sort -f | uniq -u | xargs)
            local Heading=''
            local HeadingRemove
            local HeadingAdd
            if [[ -n ${AppsToAdd-} || -n ${AppsToRemove-} ]]; then
                if [[ -n ${AppsToAdd-} ]]; then
                    local FormattedAppList
                    local HeadingAddCommand=" ${APPLICATION_COMMAND} --add "
                    local Indent='          '
                    FormattedAppList="$(printf "${Indent}%s\n" "${AppsToAdd}" | fmt -w "${COLUMNS}")"
                    HeadingAdd="Adding applications:\n${DC[CommandLine]}${HeadingAddCommand}${FormattedAppList:${#Indent}}\n"
                fi
                if [[ -n ${AppsToRemove-} ]]; then
                    local HeadingRemoveCommand=" ${APPLICATION_COMMAND} --remove "
                    local Indent='             '
                    FormattedAppList="$(printf "${Indent}%s\n" "${AppsToRemove}" | fmt -w "${COLUMNS}")"
                    HeadingRemove="${DC[Subtitle]}Removing applications:\n${DC[CommandLine]}${HeadingRemoveCommand}${FormattedAppList:${#Indent}}\n"
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
                } |& dialog_pipe "${DC[TitleSuccess]}Enabling Selected Applications" "${Heading}" "${DIALOGTIMEOUT}"
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
