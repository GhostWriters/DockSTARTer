#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    shift 3
    #local CommandLine=${*:-true}
    dialog --title "dialog_command_output" --msgbox "Title=${Title}\nSubTitle=${SubTitle}\nTimeOut=${TimeOut}\nCommandLine=$*\n" 0 0
    if [[ -t 1 ]]; then
        #eval "$*" |& run_script 'dialog_output' "${Title}" "${SubTitle}" "${TimeOut}"
        "$@" |& dialog --begin 2 2 --timeout "${TimeOut}" --title "${Title}" --programbox "${SubTitle}" $((LINES - 4)) $((COLUMNS - 5))
        return "${PIPESTATUS[0]}"
    else
        eval "$*"
    fi
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
