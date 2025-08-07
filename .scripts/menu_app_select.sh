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
#declare -a Statuses=(
#    _Waiting_
#    _InProgress_
#    _Completed_
#)
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
declare ProgressHeading=''

declare Title="Select Applications"
declare Subtitle
declare DialogGaugeText FullDialogGaugeText
declare -i ProgressSteps ProgressStepNumber

declare GaugePipe ProgressLog
declare -i GaugePipe_fd ProgressLog_fd
declare Dialog_PID

menu_app_select() {
    init_prepare_gauge_text
    show_gauge
    {
        PrepareStatus["FindAddedApps"]="_InProgress_"
        ProgressSteps=1
        ProgressStepNumber=0
        update_prepare_gauge

        readarray -t AddedApps < <(
            run_script 'app_list_added' |
                run_script 'app_filter_runnable_pipe' |
                sort -f -u |
                run_script 'app_nicename_pipe'
        )

        if [[ -n ${AddedApps[*]-} ]]; then
            local old_IFS="${IFS}"
            IFS='|'
            AddedAppsRegex="${AddedApps[*]}"
            IFS="${old_IFS}"

            printf "\nCurrently installed applications:\n\n"
            local -i TextCols
            TextCols=$((COLUMNS - DC["WindowColsAdjust"] - DC["TextColsAdjust"]))
            local Indent='   '
            local -a AddedAppsTable
            readarray -t AddedAppsTable < <(printf "%s\n" "${AddedApps[@]}")
            readarray -t AddedAppsTable < <(
                printf "%s\n" "${AddedAppsTable[@]}" |
                    column -m -c "$((TextCols - ${#Indent}))" |
                    pr -e -t -o "${#Indent}"
            )
        fi

        printf "%s\n" "${AddedAppsTable[@]}"
        update_prepare_gauge 1

        PrepareStatus["FindAddedApps"]="_Completed_"
        update_prepare_gauge

        PrepareStatus["FindBuiltinApps"]="_InProgress_"
        ProgressSteps=4
        ProgressStepNumber=0
        update_prepare_gauge

        readarray -t BuiltinApps < <(run_script 'app_list_nondeprecated')
        update_prepare_gauge 1

        readarray -t BuiltinApps < <(run_script 'app_filter_runnable' "${BuiltinApps[@]}")
        update_prepare_gauge 1

        readarray -t BuiltinApps < <(run_script 'app_nicename' "${BuiltinApps[@]}")
        update_prepare_gauge 1

        local -a AllApps
        readarray -t AllApps < <(
            printf '%s\n' "${AddedApps[@]}" "${BuiltinApps[@]}" |
                sort -f -u
        )
        update_prepare_gauge 1

        PrepareStatus["FindBuiltinApps"]="_Completed_"
        update_prepare_gauge

        local -i AppCount=${#AllApps[@]}
        PrepareStatus["ProcessAppList"]="_InProgress_"
        ProgressSteps=${AppCount}
        ProgressStepNumber=0
        update_prepare_gauge

        local LastAppLetter=''
        for AppName in "${AllApps[@]}"; do
            local AppLetter=${AppName:0:1}
            AppLetter=${AppLetter^^}
            if [[ -n ${LastAppLetter-} && ${LastAppLetter} != "${AppLetter}" ]]; then
                AppList+=("" "" "off")
            fi
            LastAppLetter=${AppLetter}
            PrepareStatus["ProcessAppList"]="${AppName}"
            update_prepare_gauge 1
            local AppDescription
            AppDescription=$(run_script 'app_description_from_template' "${AppName}")
            if [[ ${AppName} =~ ^(${AddedAppsRegex})$ ]]; then
                AppList+=("${AppName}" "${AppDescription}" "on")
            else
                AppList+=("${AppName}" "${AppDescription}" "off")
            fi
        done
        PrepareStatus["ProcessAppList"]="_Completed_"
        update_prepare_gauge
        sleep "${DIALOGTIMEOUT}"
    } &> "${ProgressLog}"
    close_gauge

    local -i SelectedAppsDialogButtonPressed
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
    else
        local SelectAppsDialogText="Choose which apps you would like to install:\n Use ${DC["KeyCap"]}[up]${DC["NC"]}, ${DC["KeyCap"]}[down]${DC["NC"]}, and ${DC["KeyCap"]}[space]${DC["NC"]} to select apps, and ${DC["KeyCap"]}[tab]${DC["NC"]} to switch to the buttons at the bottom."
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
            local -a AppsToAdd AppsToRemove
            local RemoveCommand="${APPLICATION_COMMAND} --remove"
            local AddCommand="${APPLICATION_COMMAND} --add"
            readarray -t AppsToRemove < <(
                printf '%s\n' "${AddedApps[@]}" "${SelectedApps[@]}" "${SelectedApps[@]}" |
                    sort -f |
                    uniq -u
            )
            readarray -t AppsToAdd < <(
                printf '%s\n' "${AddedApps[@]}" "${AddedApps[@]}" "${SelectedApps[@]}" |
                    sort -f |
                    uniq -u
            )
            if [[ -n ${AppsToAdd[*]-} || -n ${AppsToRemove[*]-} ]]; then
                local -a ProgressInfo=()
                if [[ -n ${AppsToRemove[*]-} ]]; then
                    ProgressInfo+=("Removing applications" "${RemoveCommand}" "${AppsToRemove[*]}")
                fi
                if [[ -n ${AppsToAdd[*]-} ]]; then
                    ProgressInfo+=("Adding applications" "${AddCommand}" "${AppsToAdd[*]}")
                fi
                ProgressInfo+=("Updating variable files" "" "")
                Subtitle=''
                ProgressSteps=0
                init_add_remove_gauge_text "${ProgressInfo[@]}"
                show_gauge "Enabling Selected Applications"
                {
                    run_script 'env_backup'
                    if [[ -n ${AppsToRemove[*]-} ]]; then
                        ProgressSteps=${#AppsToRemove[@]}
                        ProgressStepNumber=0
                        update_add_remove_gauge 0 "Removing applications" "_Waiting_" "_InProgress_"
                        update_add_remove_gauge 0 "${RemoveCommand}" "_Waiting_" "_InProgress_"
                        notice "Removing variables for deselected apps."
                        for VarName in "${AppsToRemove[@]}"; do
                            update_add_remove_gauge 0 "${VarName}" "_Waiting_" "_InProgress_"
                            run_script 'appvars_purge' "${VarName}"
                            update_add_remove_gauge 1 "${VarName}" "_InProgress_" "_Completed_"
                        done
                        update_add_remove_gauge 0 "${RemoveCommand}" "_InProgress_" "_Completed_"
                        update_add_remove_gauge 0 "Removing applications" "_InProgress_" "_Completed_"
                    fi
                    if [[ -n ${AppsToAdd[*]-} ]]; then
                        ProgressSteps=${#AppsToAdd[@]}
                        ProgressStepNumber=0
                        update_add_remove_gauge 0 "Adding applications" "_Waiting_" "_InProgress_"
                        update_add_remove_gauge 0 "${AddCommand}" "_Waiting_" "_InProgress_"
                        notice "Creating variables for selected apps."
                        for VarName in "${AppsToAdd[@]}"; do
                            update_add_remove_gauge 0 "${VarName}" "_Waiting_" "_InProgress_"
                            run_script 'appvars_create' "${VarName}"
                            run_script 'appvars_sanitize' "${VarName}"
                            update_add_remove_gauge 1 "${VarName}" "_InProgress_" "_Completed_"
                        done
                        update_add_remove_gauge 0 "${AddCommand}" "_InProgress_" "_Completed_"
                        update_add_remove_gauge 0 "Adding applications" "_InProgress_" "_Completed_"
                    fi
                    ProgressSteps=1
                    ProgressStepNumber=0
                    update_add_remove_gauge 0 "Updating variable files" "_Waiting_" "_InProgress_"
                    notice "Updating variable files"
                    run_script 'env_update'
                    update_add_remove_gauge 1 "Updating variable files" "_InProgress_" "_Completed_"
                } &> "${ProgressLog}"
            fi
            sleep "${DIALOGTIMEOUT}"
            close_gauge
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

update_gauge_percent_value() {
    local -i AddStep=${1-0}
    ProgressStepNumber+=${AddStep}
    if [[ ProgressSteps -gt 0 ]]; then
        ProgressPercent=$((100 * ProgressStepNumber / ProgressSteps))
        if [[ ProgressPercent -gt 100 ]]; then
            ProgressPercent=100
        fi
    else
        ProgressPercent=0
    fi
}
update_gauge_percent() {
    update_gauge_percent_value "${1-0}"
    echo "${ProgressPercent}" > "${GaugePipe}"
}
update_gauge() {
    update_gauge_percent_value "${1-0}"
    printf 'XXX\n%s\n%s\nXXX\n' "${ProgressPercent}" "${FullDialogGaugeText}" > "${GaugePipe}"
}

init_add_remove_gauge_text() {
    local IndentCols=3
    local SpaceCols=1
    local Indent Space
    Indent="$(printf "%${IndentCols}s" '')"
    Space="$(printf "%${SpaceCols}s" '')"
    local WaitingHighlight=${StatusHighlight["_Waiting_"]}
    local WaitingText=${StatusText["_Waiting_"]}
    local -i HeadingCols=0
    local -a HeadingText Command AppNames
    while [[ $# -gt 0 ]]; do
        HeadingText+=("${1-}")
        Command+=("${2-}")
        AppNames+=("${3-}")
        if [[ ${#HeadingText[-1]} -gt HeadingCols ]]; then
            HeadingCols=${#HeadingText[-1]}
        fi
        shift 3 || true
    done
    DialogGaugeText=''
    for index in "${!HeadingText[@]}"; do
        if [[ -n ${HeadingText[index]} ]]; then
            local -i HeadingPadCols
            HeadingPadCols=$((HeadingCols - ${#HeadingText[index]}))
            local HeadingPad
            HeadingPad="$(printf "%${HeadingPadCols}s" '')"
            DialogGaugeText+="${WaitingHighlight}${HeadingText[index]}${DC["NC"]}${HeadingPad} ${WaitingHighlight}[${WaitingText}]${DC["NC"]}\n"
        fi
        if [[ -n ${Command[index]} ]]; then
            local -i CommandCols=${#Command[index]}
            local -i TextCols
            AppsColumnStart=$((IndentCols + CommandCols + SpaceCols))
            TextCols=$((COLUMNS - DC["WindowColsAdjust"] - DC["TextColsAdjust"]))
            local -a AppNamesArray
            readarray -t AppNamesArray < <(xargs -n 1 <<< "${AppNames[index]}")

            local FormattedAppNames
            FormattedAppNames="$(
                printf "%s\n" "${AppNamesArray[@]}" |
                    fmt -w "$((TextCols - AppsColumnStart))" |
                    pr -e -t -o "${AppsColumnStart}"
            )"

            # Get the color codes to add to the app names
            local BeginHighlight="${WaitingHighlight}"
            local EndHighlight="${DC["NC"]}"
            # Escape the backslahes to be used in sed
            BeginHighlight="${BeginHighlight//\\/\\\\}"
            EndHighlight="${EndHighlight//\\/\\\\}"

            # Highlight each app name
            FormattedAppNames="$(sed -E "s/\<([A-Za-z0-9]+)\>/${BeginHighlight}\1${EndHighlight}/g" <<< "${FormattedAppNames}")"

            # Add the command name to the first line
            DialogGaugeText+="${Indent}${WaitingHighlight}${Command[index]}${DC["NC"]}${Space}${FormattedAppNames:AppsColumnStart}\n"
        fi
        DialogGaugeText+="\n"
    done
    DialogGaugeText="$(printf '%b' "${DialogGaugeText}" | expand)"
    FullDialogGaugeText="${DialogGaugeText}"
}
update_add_remove_gauge_text() {
    local SearchItem=${1-}
    local OldStatus=${2-}
    local NewStatus=${3-}
    if [[ -n ${OldStatus-} && -n ${NewStatus-} && -n ${StatusHighlight["${OldStatus-}"]-} && -n ${StatusHighlight["${NewStatus-}"]-} ]]; then
        # Escape the \ to use in sed
        local OldHighlight="${StatusHighlight["${OldStatus}"]//\\/\\\\}"
        local NewHighlight="${StatusHighlight["${NewStatus}"]//\\/\\\\}"
        local EndHighlight="${DC["NC"]//\\/\\\\}"
        local OldString="${OldHighlight}${SearchItem}${EndHighlight}"
        local NewString="${NewHighlight}${SearchItem}${EndHighlight}"
        # Escape the [ and ] to use in a sed serach string
        local OldStatusString="${OldHighlight}\\[${StatusText["${OldStatus}"]}\\]${EndHighlight}"
        local NewStatusString="${NewHighlight}[${StatusText["${NewStatus}"]}]${EndHighlight}"
        DialogGaugeText="$(sed "s/^\(${OldString}[[:space:]]\+\)${OldStatusString}/\1${NewStatusString}/ ; s/${OldString}/${NewString}/" <<< "${DialogGaugeText}")"
        FullDialogGaugeText="${DialogGaugeText}"
    fi
}
update_add_remove_gauge() {
    local -i AddStep=${1-0}
    shift || true
    update_add_remove_gauge_text "${@}"
    update_gauge "${AddStep}"
}

update_prepare_gauge_text() {
    local -a ProgressHeading=()
    for item in "${PrepareItems[@]-}"; do
        local Status="${PrepareStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]:-${StatusHighlight["_InProgress_"]}}"
        local ShowTitle="${PrepareTitle["${item}"]}"
        local ShowStatus="[${StatusText["${Status}"]:-${Status}}]"
        local -i IndentLength
        local -i TitleLength=${#ShowTitle}
        IndentLength=$((PrepareMaxTitleLength - TitleLength + 1))
        local Indent
        Indent="$(printf "%${IndentLength}s" '')"
        ProgressHeading+=("${Highlight}${ShowTitle}${DC["NC"]}${Indent}${Highlight}${ShowStatus}${DC["NC"]}")
    done
    DialogGaugeText="$(printf '%b\n' "${ProgressHeading[@]-}")"
    if [[ -z ${Subtitle-} ]]; then
        FullDialogGaugeText="${DialogGaugeText}"
    else
        FullDialogGaugeText="$(printf '%b\n' "${Subtitle}")${DialogGaugeText}"
    fi
}
init_prepare_gauge_text() {
    update_prepare_gauge_text
}
update_prepare_gauge() {
    local -i AddStep=${1-0}
    local -i AddStep=${1-0}
    update_prepare_gauge_text
    update_gauge "${AddStep}"
}

show_gauge() {
    local GaugeTitle="${1-${Title}}"

    _dialog_backtitle_
    local -a GlobalDialogOptions=(
        --backtitle "${BACKTITLE}"
        --no-collapse
        --cr-wrap
        --colors
    )

    local -i ScreenRows=${LINES}
    local -i ScreenCols=${COLUMNS}
    local -i DialogCols
    #local -i DialogRows

    local -i GaugeDialogStartRow
    local -i LogDialogStartRow
    local -i DialogStartCol

    local -i GaugeDialogRows
    local -i LogDialogRows

    local -i GaugeDialogTextRows

    GaugeDialogStartRow=2
    DialogStartCol=2

    #DialogRows=$((ScreenRows - DC["WindowRowsAdjust"]))
    DialogCols=$((ScreenCols - DC["WindowColsAdjust"]))

    GaugeDialogTextRows=$(wc -l <<< "${FullDialogGaugeText}")
    GaugeDialogRows=$((GaugeDialogTextRows + DC["TextRowsAdjust"]))

    LogDialogStartRow="$((GaugeDialogStartRow + GaugeDialogRows + (DC["WindowRowsAdjust"] - 3)))"
    LogDialogRows="$((ScreenRows - LogDialogStartRow - (DC["WindowRowsAdjust"] - 3) - 1))"

    # Create the pipes to communicate with the gauge and log dialog windows
    GaugePipe=$(mktemp -u -t "${APPLICATION_NAME}.${FUNCNAME[0]}.GaugePipe.XXXXXXXXXX")
    mkfifo "${GaugePipe}"
    exec {GaugePipe_fd}<> "${GaugePipe}"
    ProgressLog=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ProgressLog.XXXXXXXXXX")
    exec {ProgressLog_fd}<> "${ProgressLog}"

    local -a GaugeDialog=(
        "${GlobalDialogOptions[@]}"
        --title "${DC["TitleSuccess"]}${GaugeTitle}"
        --begin "${GaugeDialogStartRow}" "${DialogStartCol}"
        --gauge "${DialogGaugeText}"
        "${GaugeDialogRows}" "${DialogCols}"
        0
    )
    local -a LogDialog=(
        "${GlobalDialogOptions[@]}"
        --title "${DC["Title"]}Log Output"
        --begin "${LogDialogStartRow}" "${DialogStartCol}"
        --keep-window
        --tailboxbg "${ProgressLog}"
        "${LogDialogRows}" "${DialogCols}"
    )
    local DialogOptions=(
        "${LogDialog[@]}"
        --and-widget
        "${GaugeDialog[@]}"
    )

    # Start the gauge and progress dialog windows in the background, and get the process id
    "${DIALOG}" "${DialogOptions[@]}" < "${GaugePipe}" &
    Dialog_PID=$!
}
close_gauge() {
    # Signal the dialog gauge and progress windows to terminate
    kill -SIGTERM "${Dialog_PID}"
    wait "${Dialog_PID}"
    # Remove the communication pipes to dialog
    exec {GaugePipe_fd}>&-
    rm "${GaugePipe}" || true
    exec {ProgressLog_fd}>&-
    rm "${ProgressLog}" || true
}
test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
