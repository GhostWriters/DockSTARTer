#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Applications"

    local -a AppList AddedApps BuiltinApps
    local AddedAppsRegex=''

    local -a ProgressItems=(
        "FindAddedApps"
        "FindBuiltinApps"
        "ProcessAppList"
    )
    local -A ProgressTitle=(
        ["FindAddedApps"]="Detecting installed applications"
        ["FindBuiltinApps"]="${DC["Subtitle"]}Detecting built in applications"
        ["ProcessAppList"]="Processing application list to create menu"
    )

    local -A StatusText=(
        ["Waiting"]="Waiting"
        ["InProgress"]="In Progress"
        ["Completed"]="Completed"
    )
    local -A StatusHighlight=(
        ["Waiting"]="${DC[NC]}"
        ["InProgress"]="${DC[NC]}"
        ["Completed"]="${DC[NC]}${DC["Subtitle"]}"
    )

    local -A ProgressStatus
    for item in "${ProgressItems[@]}"; do
        ProgressStatus["${item}"]="Waiting"
    done
    local -i ProgressPercent=0

    local ProgressMessage="${DC["Subtitle"]}Preparing app menu. Please be patient, this can take a while.${DC[NC]}"

    ProgressStatus["FindAddedApps"]="InProgress"
    ProgressOptions=()
    for item in "${ProgressItems[@]}"; do
        local Status="${ProgressStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]}"
        local ShowStatus="${StatusText["${Status}"]}"
        ProgressOptions+=("${Highlight}${ProgressTitle["${item}"]}${DC[NC]}" "${ShowStatus}")
    done
    dialog_mixedgauge "${DC["TitleSuccess"]}${Title}" "${ProgressMessage}" "${ProgressPercent}" "${ProgressOptions[@]}"

    readarray -t AddedApps < <(
        run_script 'app_list_added' |
            run_script 'app_filter_runnable_pipe' |
            tr '[:upper:]' '[:lower:]' |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null

    if [[ -n ${AddedApps[*]} ]]; then
        local Indent='   '
        # Escape \ with \\ to use in sed
        local HighlightReplace="${DC["Highlight"]//\\/\\\\}"
        local NCReplace="${DC["NC"]//\\/\\\\}"
        local -i TextCols
        TextCols=$((COLUMNS - DC["WindowColsAdjust"] - DC["TextColsAdjust"] - ${#Indent}))
        local AddedAppsText
        AddedAppsText="$(printf '%s\n' "${AddedApps[@]}" | column -c "${TextCols}")"
        AddedAppsText="$(sed -E "s/^/${Indent}/g ; s/(\<[a-zA-Z0-9_]*\>)/${HighlightReplace}\1${NCReplace}/g" <<< "${AddedAppsText}")"
        ProgressMessage+="\n\nCurrently installed applications:\n\n${AddedAppsText}\n"
        {
            IFS='|'
            AddedAppsRegex="${AddedApps[*]}"
        }
    fi
    ProgressPercent+=10
    ProgressStatus["FindAddedApps"]="Completed"
    ProgressStatus["FindBuiltinApps"]="InProgress"

    ProgressOptions=()
    for item in "${ProgressItems[@]}"; do
        local Status="${ProgressStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]}"
        local ShowStatus="${StatusText["${Status}"]}"
        ProgressOptions+=("${Highlight}${ProgressTitle["${item}"]}${DC[NC]}" "${ShowStatus}")
    done
    dialog_mixedgauge "${DC["TitleSuccess"]}${Title}" "${ProgressMessage}" "${ProgressPercent}" "${ProgressOptions[@]}"

    readarray -t BuiltinApps < <(
        run_script 'app_list_nondeprecated' |
            run_script 'app_filter_runnable_pipe'
    ) 2> /dev/null
    ProgressPercent+=10
    ProgressStatus["FindBuiltinApps"]="Completed"
    ProgressStatus["ProcessAppList"]="InProgress"

    ProgressOptions=()
    for item in "${ProgressItems[@]}"; do
        local Status="${ProgressStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]}"
        local ShowStatus="${StatusText["${Status}"]}"
        ProgressOptions+=("${Highlight}${ProgressTitle["${item}"]}${DC[NC]}" "${ShowStatus}")
    done
    dialog_mixedgauge "${DC["TitleSuccess"]}${Title}" "${ProgressMessage}" "${ProgressPercent}" "${ProgressOptions[@]}"

    local -a AllApps
    readarray -t AllApps < <(
        printf '%s\n' "${AddedApps[@],,}" "${BuiltinApps[@],,}" |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null
    ProgressPercent+=10

    local InitialPercent=${ProgressPercent}
    ProgressStatus["ProcessAppList"]="InProgress"
    local -i AppCount=${#AllApps[@]}
    local LastAppLetter=''
    for AppNumber in "${!AllApps[@]}"; do
        ProgressPercent=$((InitialPercent + ((100 - InitialPercent) * AppNumber / AppCount)))
        local AppName
        AppName="${AllApps["${AppNumber}"]}"
        local AppLetter=${AppName:0:1}
        AppLetter=${AppLetter^^}
        if [[ -n ${LastAppLetter-} && ${LastAppLetter} != "${AppLetter}" ]]; then
            ProgressOptions=()
            for item in "${ProgressItems[@]}"; do
                local Status="${ProgressStatus["${item}"]}"
                local Highlight="${StatusHighlight["${Status}"]}"
                local ShowStatus="${StatusText["${Status}"]}"
                if [[ ${item} == "ProcessAppList" ]]; then
                    ShowStatus="${AppLetter}"
                fi
                ProgressOptions+=("${Highlight}${ProgressTitle["${item}"]}${DC[NC]}" "${ShowStatus}")
            done
            dialog_mixedgauge "${DC["TitleSuccess"]}${Title}" "${ProgressMessage}" "${ProgressPercent}" "${ProgressOptions[@]}"
            AppList+=("" "" "off")
        fi
        LastAppLetter=${AppLetter}
        AppName=$(run_script 'app_nicename' "${AppName}")
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

dialog_mixedgauge() {
    local Title=${1:-}
    local Message=${2:-}
    shift 2
    Title="$(strip_ansi_colors "${Title}")"
    Message="$(strip_ansi_colors "${Message}")"
    _dialog_ \
        --title "${Title}" \
        --mixedgauge "${Message}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" \
        "${@}"
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
