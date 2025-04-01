#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local Title=${1:-}
    local CommandLine=${2:-}
    local TimeOut=${3:-0}
    dialog --begin 2 2 --timeout "${TimeOut}" --title "${Title}" --prgbox "${CommandLine}" $((LINES - 4)) $((COLUMNS - 5))
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
