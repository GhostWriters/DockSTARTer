#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local CommandLine=${1:-}
    local Title=${2:-}
    local SubTitle=${3:-}
    local TimeOut=${4:-0}
    dialog --begin 2 2 --timeout "${TimeOut}" --title "${Title}" --prgbox "${SubTitle}" "${CommandLine}" $((LINES - 4)) $((COLUMNS - 5))
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
