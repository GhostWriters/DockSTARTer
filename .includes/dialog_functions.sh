#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

_dialog_backtitle_() {
    local LeftBackTitle RightBackTitle
    local CleanLeftBackTitle CleanRightBackTitle

    CleanLeftBackTitle="${APPLICATION_NAME}"
    LeftBackTitle="${DC["ApplicationName"]-}${APPLICATION_NAME}${DC["NC"]-}"

    CleanRightBackTitle=''
    RightBackTitle=''
    if ds_update_available; then
        CleanRightBackTitle="(Update Available)"
        RightBackTitle="${DC["ApplicationUpdateBrackets"]-}(${DC["ApplicationUpdate"]-}Update Available${DC["ApplicationUpdateBrackets"]-})${DC["NC"]-}"
    fi
    if [[ ${APPLICATION_VERSION-} ]]; then
        if [[ -n ${CleanRightBackTitle-} ]]; then
            CleanRightBackTitle+=" "
            RightBackTitle+="${DC["ApplicationVersionSpace"]-} "
        fi
        local CurrentVersion
        CurrentVersion="$(ds_version)"
        if [[ -z ${CurrentVersion} ]]; then
            CurrentVersion="$(ds_branch) Unknown Version"
        fi
        CleanRightBackTitle+="[${CurrentVersion}]"
        RightBackTitle+="${DC["ApplicationVersionBrackets"]-}[${DC["ApplicationVersion"]-}${CurrentVersion}${DC["ApplicationVersionBrackets"]-}]${DC["NC"]-}"
    fi

    local -i IndentLength
    IndentLength=$((COLUMNS - ${#CleanLeftBackTitle} - ${#CleanRightBackTitle} - 2))
    local Indent
    Indent="$(printf %${IndentLength}s '')"
    BACKTITLE="${LeftBackTitle}${Indent}${RightBackTitle}"
}

_dialog_() {
    _dialog_backtitle_
    ${DIALOG} --file "${DIALOG_OPTIONS_FILE}" --backtitle "${BACKTITLE}" "$@"
}

# Check to see if we should use a dialog box
use_dialog_box() {
    [[ ${PROMPT:-CLI} == GUI && -t 1 && -t 2 ]]
}

# Pipe to Dialog Box Function
dialog_pipe() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    _dialog_ \
        --title "${DC["Title"]-}${Title}" \
        --timeout "${TimeOut}" \
        --programbox "${DC["Subtitle"]-}${SubTitle}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" || true
    echo -n "${BS}"
}
# Script Dialog Runner Function
run_script_dialog() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    local SCRIPTSNAME=${4-}
    shift 4
    if use_dialog_box; then
        # Using the GUI, pipe output to a dialog box
        SubTitle="$(strip_ansi_colors "${SubTitle}")"
        coproc {
            dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        local -i result=0
        run_script "${SCRIPTSNAME}" "$@" >&${DialogBox_FD} 2>&1 || result=$?
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
        return ${result}
    else
        run_script "${SCRIPTSNAME}" "$@"
        return
    fi
}

# Command Dialog Runner Function
run_command_dialog() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    local CommandName=${4-}
    shift 4
    if [[ -n ${CommandName-} ]]; then
        if use_dialog_box; then
            # Using the GUI, pipe output to a dialog box
            SubTitle="$(strip_ansi_colors "${SubTitle}")"
            "${CommandName}" "$@" |& dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
            return "${PIPESTATUS[0]}"
        else
            "${CommandName}" "$@"
            return
        fi
    fi
}

dialog_info() {
    local Title=${1:-}
    local Message=${2:-}
    Title="$(strip_ansi_colors "${Title}")"
    Message="$(strip_ansi_colors "${Message}")"
    _dialog_ \
        --title "${Title}" \
        --infobox "${Message}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
    echo -n "${BS}"
}
dialog_message() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    Title="$(strip_ansi_colors "${Title}")"
    Message="$(strip_ansi_colors "${Message}")"
    _dialog_ \
        --title "${Title}" \
        --timeout "${TimeOut}" \
        --msgbox "${Message}" \
        "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
    echo -n "${BS}"
}
dialog_error() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleError"]-}${Title}" "${Message}" "${TimeOut}"
}
dialog_warning() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleWarning"]-}${Title}" "${Message}" "${TimeOut}"
}
dialog_success() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    dialog_message "${DC["TitleSuccess"]-}${Title}" "${Message}" "${TimeOut}"
}
