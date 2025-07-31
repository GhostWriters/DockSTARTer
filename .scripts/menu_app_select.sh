#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a AppList AddedApps BuiltinApps
declare AddedAppsRegex=''

declare -a ProgressItems=(
    "FindAddedApps"
    "FindBuiltinApps"
    "ProcessAppList"
)
declare -A ProgressTitle=(
    ["FindAddedApps"]="Detecting installed applications"
    ["FindBuiltinApps"]="Detecting built in applications"
    ["ProcessAppList"]="Processing application list to create menu"
)
declare -i ProgressTitleLength=0
for item in "${ProgressTitle[@]}"; do
    ProgressTitleLength=$((ProgressTitleLength < ${#item} ? ${#item} : ProgressTitleLength))
done
declare -A StatusText=(
    ["_Waiting_"]="  Waiting  "
    ["_InProgress_"]="In Progress"
    ["_Completed_"]=" Completed "
)
declare -A StatusHighlight=(
    ["_Waiting_"]="${DC[NC]}"
    ["_InProgress_"]="${DC[NC]}"
    ["_Completed_"]="${DC[NC]}${DC["Subtitle"]}"
)

declare -A ProgressStatus
for item in "${ProgressItems[@]}"; do
    ProgressStatus["${item}"]="Waiting"
done
declare -i ProgressPercent=0
declare ProgressHeading=''

declare Title="Select Applications"
declare Subtitle="Preparing app menu. Please be patient, this can take a while."
declare DialogGaugeText=''
declare DIALOG_PID
declare GaugePipe

menu_app_select() {
    ProgressPercent=0
    ProgressStatus["FindAddedApps"]="_InProgress_"
    show_gauge

    readarray -t AddedApps < <(
        run_script 'app_list_added' |
            run_script 'app_filter_runnable_pipe' |
            tr '[:upper:]' '[:lower:]' |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null

    if [[ -n ${AddedApps[*]} ]]; then
        {
            IFS='|'
            AddedAppsRegex="${AddedApps[*]}"
        }
    fi

    ProgressPercent+=5
    ProgressStatus["FindAddedApps"]="_Completed_"
    ProgressStatus["FindBuiltinApps"]="_InProgress_"
    update_gauge

    readarray -t BuiltinApps < <(
        run_script 'app_list_nondeprecated' |
            run_script 'app_filter_runnable_pipe'
    ) 2> /dev/null

    ProgressPercent+=5
    ProgressStatus["FindBuiltinApps"]="_Completed_"
    ProgressStatus["ProcessAppList"]="_InProgress_"
    update_gauge

    local -a AllApps
    readarray -t AllApps < <(
        printf '%s\n' "${AddedApps[@],,}" "${BuiltinApps[@],,}" |
            sort -u |
            run_script 'app_nicename_pipe'
    ) 2> /dev/null

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
        ProgressStatus["ProcessAppList"]="${AppName}"
        update_gauge
        local AppDescription
        AppDescription=$(run_script 'app_description_from_template' "${AppName}")
        if [[ ${AppName} =~ ${AddedAppsRegex} ]]; then
            AppList+=("${AppName}" "${AppDescription}" "on")
        else
            AppList+=("${AppName}" "${AppDescription}" "off")
        fi
        ProgressPercent=$((InitialPercent + ((100 - InitialPercent) * AppNumber / AppCount)))
        ProgressStatus["ProcessAppList"]="${AppName}"
        update_gauge
    done
    ProgressPercent=100
    ProgressStatus["ProcessAppList"]="_Completed_"
    update_gauge

    close_gauge

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

update_gauge_text() {
    DialogGaugeText=''
    if [[ -n ${Subtitle-} ]]; then
        DialogGaugeText+="${DC["Subtitle"]}${Subtitle}${DC["NC"]}\n\n"
    fi
    local -i TextCols
    TextCols=$((COLUMNS - DC["WindowColsAdjust"] - DC["TextColsAdjust"]))
    local ProgressHeading=''
    for item in "${ProgressItems[@]}"; do
        local Status="${ProgressStatus["${item}"]}"
        local Highlight="${StatusHighlight["${Status}"]:-${StatusHighlight["_InProgress_"]}}"
        local ShowTitle="${ProgressTitle["${item}"]}"
        local ShowStatus="${StatusText["${Status}"]:-${Status}}"
        local -i IndentLength
        IndentLength=$((ProgressTitleLength - ${#ShowTitle} + 1))
        local Indent
        Indent="$(printf %${IndentLength}s '')"
        ProgressHeading+="${Highlight}${ShowTitle}${DC[NC]}${Indent}${Highlight}[${ShowStatus}]${DC[NC]}\n"
    done
    DialogGaugeText+="${ProgressHeading}\n"
    if [[ -n ${AddedApps[*]-} ]]; then
        DialogGaugeText+="\nCurrently installed applications:\n\n"
        local Indent='   '
        # Escape \ with \\ to use in sed
        local HighlightReplace="${DC["Highlight"]//\\/\\\\}"
        local NCReplace="${DC["NC"]//\\/\\\\}"
        local AddedAppsText
        AddedAppsText="$(printf '%s\n' "${AddedApps[@]}" | column -c "$((TextCols - ${#Indent}))")"
        AddedAppsText="$(sed -E "s/^/${Indent}/g ; s/(\<[a-zA-Z0-9_]*\>)/${HighlightReplace}\1${NCReplace}/g" <<< "${AddedAppsText}")"
        DialogGaugeText+="${AddedAppsText}\n"
    fi
    DialogGaugeText="$(printf '%b' "${DialogGaugeText}")"
}
update_gauge() {
    update_gauge_text
    local Output="XXX\n${ProgressPercent}\n${DialogGaugeText}\nXXX\n"
    printf '%b' "${Output}" > "${GaugePipe}"
}

show_gauge() {
    update_gauge_text
    local -a GaugeDialog=(
        --input-fd 5
        --title "${DC["TitleSuccess"]}${Title}"
        --gauge "${DialogGaugeText}"
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
        "${ProgressPercent}"
    )
    GaugePipe=$(mktemp -u)
    mkfifo "${GaugePipe}"
    exec 5<> "${GaugePipe}"
    _dialog_ "${GaugeDialog[@]}" < "${GaugePipe}" &
    # shellcheck disable=SC2034 # (warning): DIALOG_PID appears unused. Verify use (or export if used externally).
    DIALOG_PID=$!
}
close_gauge() {
    kill "${DIALOG_PID}"
    exec 5>&-
    rm "${GaugePipe}"
}
test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
