#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a AppList AddedApps BuiltinApps
declare AddedAppsRegex=''

declare -a PrepareItems=(
    "FindAddedApps"
    "FindBuiltinApps"
    "ProcessAppList"
)
declare -A PrepareTitle=(
    ["FindAddedApps"]="Detecting installed applications"
    ["FindBuiltinApps"]="Detecting built in applications"
    ["ProcessAppList"]="Processing application list to create menu"
)
declare -i PrepareMaxTitleLength=0
for item in "${PrepareTitle[@]}"; do
    PrepareMaxTitleLength=$((${#item} > PrepareMaxTitleLength ? ${#item} : PrepareMaxTitleLength))
done
declare -A StatusText=(
    ["_Waiting_"]="  Waiting  "
    ["_InProgress_"]="In Progress"
    ["_Completed_"]=" Completed "
)
declare -A StatusHighlight=(
    ["_Waiting_"]="${DC["ProgressWaiting"]}"
    ["_InProgress_"]="${DC["ProgressInProgress"]}"
    ["_Completed_"]="${DC["ProgressCompleted"]}"
)

declare -A PrepareStatus
for item in "${PrepareItems[@]}"; do
    PrepareStatus["${item}"]="_Waiting_"
done
declare -i ProgressPercent=0
declare ProgressHeading=''

declare Title="Select Applications"
declare DialogGaugeText=''
declare GaugePipe ProgressLog
declare -i GaugePipe_fd ProgressLog_fd
declare Dialog_PID

menu_app_select() {
    ProgressPercent=0
    PrepareStatus["FindAddedApps"]="_InProgress_"
    update_gauge_text
    show_gauge

    readarray -t AddedApps < <(
        run_script 'app_list_added' |
            run_script 'app_filter_runnable_pipe' |
            tr '[:upper:]' '[:lower:]' |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2>> "${ProgressLog}"

    if [[ -n ${AddedApps[*]} ]]; then
        {
            IFS='|'
            AddedAppsRegex="${AddedApps[*]}"
        }
    fi

    if [[ -n ${AddedApps[*]-} ]]; then
        printf "\nCurrently installed applications:\n\n" >> "${ProgressLog}"
        local -i TextCols
        TextCols=$((COLUMNS - DC["WindowColsAdjust"] - DC["TextColsAdjust"]))
        local Indent='   '
        local -a AddedAppsTable
        readarray -t AddedAppsTable < <(printf "%s\n" "${AddedApps[@]}")
        readarray -t AddedAppsTable < <(
            printf "%s\n" "${AddedAppsTable[@]}" |
                column -c "$((TextCols - ${#Indent}))" |
                pr -to ${#Indent}
        )
        printf "%s\n" "${AddedAppsTable[@]}" >> "${ProgressLog}"
    fi
    ProgressPercent+=5
    PrepareStatus["FindAddedApps"]="_Completed_"
    PrepareStatus["FindBuiltinApps"]="_InProgress_"
    update_gauge

    readarray -t BuiltinApps < <(
        run_script 'app_list_nondeprecated' |
            run_script 'app_filter_runnable_pipe'
    ) 2>> "${ProgressLog}"

    ProgressPercent+=5
    PrepareStatus["FindBuiltinApps"]="_Completed_"
    PrepareStatus["ProcessAppList"]="_InProgress_"
    update_gauge

    local -a AllApps
    readarray -t AllApps < <(
        printf '%s\n' "${AddedApps[@],,}" "${BuiltinApps[@],,}" |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2>> "${ProgressLog}"

    ProgressPercent+=5
    update_gauge

    local InitialPercent=${ProgressPercent}
    local -i AppCount=${#AllApps[@]}
    local LastAppLetter=''
    for AppNumber in "${!AllApps[@]}"; do
        local AppName
        AppName="${AllApps["${AppNumber}"]}"
        local AppLetter=${AppName:0:1}
        AppLetter=${AppLetter^^}
        if [[ -n ${LastAppLetter-} && ${LastAppLetter} != "${AppLetter}" ]]; then
            AppList+=("" "" "off")
        fi
        LastAppLetter=${AppLetter}
        AppName=$(run_script 'app_nicename' "${AppName}")
        ProgressPercent=$((InitialPercent + ((100 - InitialPercent) * AppNumber / AppCount)))
        PrepareStatus["ProcessAppList"]="${AppName}"
        update_gauge
        local AppDescription
        AppDescription=$(run_script 'app_description_from_template' "${AppName}")
        if [[ ${AppName} =~ ^(${AddedAppsRegex})$ ]]; then
            AppList+=("${AppName}" "${AppDescription}" "on")
        else
            AppList+=("${AppName}" "${AppDescription}" "off")
        fi
        ProgressPercent=$((InitialPercent + ((100 - InitialPercent) * AppNumber / AppCount)))
        PrepareStatus["ProcessAppList"]="${AppName}"
        update_gauge
    done
    ProgressPercent=100
    PrepareStatus["ProcessAppList"]="_Completed_"
    update_gauge
    sleep 1

    close_gauge

    local -i SelectedAppsDialogButtonPressed
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
    else
        local SelectAppsDialogText="Choose which apps you would like to install:\n Use ${DC["KeyCap"]}[up]${DC[NC]}, ${DC["KeyCap"]}[down]${DC[NC]}, and ${DC["KeyCap"]}[space]${DC[NC]} to select apps, and ${DC["KeyCap"]}[tab]${DC[NC]} to switch to the buttons at the bottom."
        local SelectedAppsDialogParams=(
            --title "${DC["Title"]}${Title}"
            --output-fd 1
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

update_gauge_text() {
    DialogGaugeText=''
    local -a ProgressHeading
    local Subtitle="Preparing app menu. Please be patient, this can take a while."
    ProgressHeading+=("${DC["Subtitle"]}${Subtitle}${DC["NC"]}" "")
    for item in "${PrepareItems[@]-}"; do
        local Status="${PrepareStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]:-${StatusHighlight["_InProgress_"]}}"
        local ShowTitle="${PrepareTitle["${item}"]}"
        local ShowStatus="${StatusText["${Status}"]:-${Status}}"
        local -i IndentLength
        local -i TitleLength=${#ShowTitle}
        IndentLength=$((PrepareMaxTitleLength - TitleLength + 1))
        local Indent
        Indent="$(printf "%${IndentLength}s" '')"
        ProgressHeading+=("${Highlight}${ShowTitle}${DC[NC]}${Indent}${Highlight}[${ShowStatus}]${DC[NC]}")
    done
    DialogGaugeText="$(printf '%s\n' "${ProgressHeading[@]-}")"
}
update_gauge() {
    update_gauge_text
    local Output="XXX\n${ProgressPercent}\n${DialogGaugeText}\nXXX\n"
    printf '%b' "${Output}" > "${GaugePipe}"
}

show_gauge() {
    GaugePipe=$(mktemp -u -t "${APPLICATION_NAME}.${FUNCNAME[0]}.GaugePipe.XXXXXXXXXX")
    mkfifo "${GaugePipe}"
    exec {GaugePipe_fd}<> "${GaugePipe}"
    ProgressLog=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ProgressLog.XXXXXXXXXX")
    exec {ProgressLog_fd}<> "${ProgressLog}"
    local -i ScreenRows=${LINES}
    local -i ScreenCols=${COLUMNS}
    local -i GaugeDialogStartRow GaugeDialogTextRows GaugeDialogRows
    GaugeDialogStartRow=2
    GaugeDialogTextRows=5
    GaugeDialogRows="$((GaugeDialogTextRows + DC["TextRowsAdjust"]))"
    local -i LogDialogStartRow LogDialogRows
    LogDialogStartRow="$((GaugeDialogStartRow + GaugeDialogRows + (DC["WindowRowsAdjust"] - 3)))"
    LogDialogRows="$((ScreenRows - LogDialogStartRow - (DC["WindowRowsAdjust"] - 3) - 1))"
    _dialog_backtitle_
    local -a GaugeDialog=(
        --begin "${GaugeDialogStartRow}" 2
        --backtitle "${BACKTITLE}"
        --title "${DC["TitleSuccess"]}${Title}"
        --no-trim
        --no-collapse
        --cr-wrap
        --gauge "${DialogGaugeText}"
        "${GaugeDialogRows}" "$((ScreenCols - DC["WindowColsAdjust"]))"
        "${ProgressPercent}"
    )
    local -a LogDialog=(
        --begin "${LogDialogStartRow}" 2
        --backtitle "${BACKTITLE}"
        --title "${DC["Title"]}Log Output"
        --keep-window
        --no-trim
        --tailboxbg "${ProgressLog}"
        "${LogDialogRows}" "$((ScreenCols - DC["WindowColsAdjust"]))"
    )
    local DialogOptions=(
        "${LogDialog[@]}"
        --and-widget
        "${GaugeDialog[@]}"
    )
    #local DialogOptions=(
    #    "${GaugeDialog[@]}"
    #)
    _dialog_backtitle_
    "${DIALOG}" "${DialogOptions[@]}" < "${GaugePipe}" &
    Dialog_PID=$!
}
close_gauge() {
    kill -SIGTERM "${Dialog_PID}"
    wait "${Dialog_PID}"
    exec {GaugePipe_fd}>&-
    rm "${GaugePipe}" || true
    exec {ProgressLog_fd}>&-
    rm "${ProgressLog}" || true
}
test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
