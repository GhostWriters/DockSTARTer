#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx DIALOG
DIALOG=$(command -v dialog) || true

declare -Agx DC

declare -rgx DIALOGRC_NAME='.dialogrc'
declare -rgx DIALOGRC="${SCRIPTPATH}/${DIALOGRC_NAME}"
declare -rgx DIALOG_OPTIONS_FILE="${SCRIPTPATH}/.dialogoptions"

declare -rigx DIALOGTIMEOUT=3
declare -rigx DIALOG_OK=0
declare -rigx DIALOG_CANCEL=1
declare -rigx DIALOG_HELP=2
declare -rigx DIALOG_EXTRA=3
declare -rigx DIALOG_ITEM_HELP=4
declare -rigx DIALOG_ERROR=254
declare -rigx DIALOG_ESC=255
declare -ragx DIALOG_BUTTONS=(
    [DIALOG_OK]="OK"
    [DIALOG_CANCEL]="CANCEL"
    [DIALOG_HELP]="HELP"
    [DIALOG_EXTRA]="EXTRA"
    [DIALOG_ITEM_HELP]="ITEM_HELP"
    [DIALOG_ERROR]="ERROR"
    [DIALOG_ESC]="ESC"
)

declare -gx BACKTITLE=''

_dialog_backtitle_() {
    local LeftHeading CenterHeading RightHeading

    local LeftHeading="${DC["Hostname"]-}${HOSTNAME}${DC["NC"]-}"
    local -A FlagOption=(
        ["DEBUG"]="DEBUG"
        ["FORCE"]="FORCE"
        ["VERBOSE"]="VERBOSE"
        ["ASSUMEYES"]="YES"
    )
    local FlagsEnabled
    for Flag in DEBUG FORCE VERBOSE ASSUMEYES; do
        if [[ -n ${!Flag-} ]]; then
            if [[ -n ${FlagsEnabled-} ]]; then
                FlagsEnabled+="${DC["ApplicationFlagsSpace"]-}|${DC["NC"]-}"
            fi
            FlagsEnabled+="${DC["ApplicationFlags"]-}${FlagOption["${Flag}"]}${DC["NC"]-}"
        fi
    done
    if [[ -n ${FlagsEnabled-} ]]; then
        LeftHeading+=" ${DC["ApplicationFlagsBrackets"]-}|${FlagsEnabled}${DC["ApplicationFlagsBrackets"]-}|${DC["NC"]-}"
    fi
    local CenterHeading="${DC["ApplicationName"]-}${APPLICATION_NAME}${DC["NC"]-}"

    local RightHeading=''

    if ds_update_available; then
        if [[ -n ${RightHeading-} ]]; then
            RightHeading+=" "
        fi
        RightHeading+="${DC["ApplicationUpdateBrackets"]-}(${DC["ApplicationUpdate"]-}Update Available${DC["ApplicationUpdateBrackets"]-})${DC["NC"]-}"
    fi
    if [[ ${APPLICATION_VERSION-} ]]; then
        if [[ -n ${RightHeading-} ]]; then
            RightHeading+=" "
        fi
        local CurrentVersion
        CurrentVersion="$(ds_version)"
        if [[ -z ${CurrentVersion} ]]; then
            CurrentVersion="$(ds_branch) Unknown Version"
        fi
        RightHeading+="${DC["ApplicationVersionBrackets"]-}[${DC["ApplicationVersion"]-}${CurrentVersion}${DC["ApplicationVersionBrackets"]-}]${DC["NC"]-}"
    fi

    local -i HeadingLength
    HeadingLength=$((COLUMNS - 2))

    local CleanLeftHeading CleanCenterHeading CleanRightHeading
    CleanLeftHeading="$(strip_dialog_colors "${LeftHeading}")"
    CleanCenterHeading="$(strip_dialog_colors "${CenterHeading}")"
    CleanRightHeading="$(strip_dialog_colors "${RightHeading}")"

    # Get the length of each heading
    local -i LeftHeadingLength=${#CleanLeftHeading}
    local -i CenterHeadingLength=${#CleanCenterHeading}
    local -i RightHeadingLength=${#CleanRightHeading}

    # Calculate padding
    local -i LeftPadding=$(((HeadingLength - CenterHeadingLength) / 2 - LeftHeadingLength))
    # Ensure left padding is not negative
    if [[ LeftPadding -lt 0 ]]; then
        LeftPadding=0
    fi
    local -i EndOfCenterHeading=$((LeftHeadingLength + LeftPadding + CenterHeadingLength))

    # Recalculate right padding based on adjusted left padding
    local RightPadding=$((HeadingLength - EndOfCenterHeading - RightHeadingLength))

    # Ensure right padding is not negative
    if [[ RightPadding -lt 0 ]]; then
        RightPadding=0
    fi

    BACKTITLE="$(
        printf "%s%*s%s%*s%s" \
            "${LeftHeading}" \
            "${LeftPadding}" " " \
            "${CenterHeading}" \
            "${RightPadding}" " " \
            "${RightHeading}"
    )"
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
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
    Title="$(strip_ansi_colors "${Title}")"
    SubTitle="$(strip_ansi_colors "${SubTitle}")"
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
        if [[ -z ${DC["_defined_"]-} ]]; then
            run_script 'apply_theme'
        fi
        # Using the GUI, pipe output to a dialog box
        coproc {
            dialog_pipe "${Title}" "${SubTitle}" "${TimeOut}"
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        local -i result=0
        run_script "${SCRIPTSNAME}" "$@" >&${DialogBox_FD} 2>&1 || result=$?
        exec {DialogBox_FD}<&- &> /dev/null || true
        wait ${DialogBox_PID} &> /dev/null || true
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
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
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
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
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
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
    dialog_message "${DC["TitleError"]-}${Title}" "${Message}" "${TimeOut}"
}
dialog_warning() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
    dialog_message "${DC["TitleWarning"]-}${Title}" "${Message}" "${TimeOut}"
}
dialog_success() {
    local Title=${1:-}
    local Message=${2:-}
    local TimeOut=${3:-0}
    if [[ -z ${DC["_defined_"]-} ]]; then
        run_script 'apply_theme'
    fi
    dialog_message "${DC["TitleSuccess"]-}${Title}" "${Message}" "${TimeOut}"
}
