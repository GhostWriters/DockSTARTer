#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    shift 3
    #local CommandLine=${*:-true}
    dialog --title "dialog_command_output" --msgbox "CommandLine=$*\nTitle=${Title}\nSubTitle=${SubTitle}\nTimeOut=${TimeOut}\n" 0 0
    if [[ -t 1 ]]; then
        eval "$* |& run_script 'dialog_output' \"${Title}\" \"${SubTitle}\" \"${TimeOut}\""
        #return "${PIPESTATUS[0]}"
    else
        "$@"
    fi
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
