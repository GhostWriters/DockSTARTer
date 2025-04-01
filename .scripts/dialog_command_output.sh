#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local CommandLine=${1:-echo}
    local Title=${2:-}
    local SubTitle=${3:-}
    local TimeOut=${4:-0}
    eval "${CommandLine}" |& dialog --begin 2 2 --timeout "${TimeOut}" --title "${Title}" --programbox "${SubTitle}" $((LINES - 4)) $((COLUMNS - 5))
    return "${PIPESTATUS[0]}"
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
