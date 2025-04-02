#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_command_output() {
    local CommandLine=${1:-true}
    local Title=${2:-}
    local SubTitle=${3:-}
    local TimeOut=${4:-0}
    if [[ -t 1 ]]; then
        eval "${CommandLine}" |& dialog "${Title}" "${SubTitle}" "${TimeOut}"
        return "${PIPESTATUS[0]}"
    else
        eval "${CommandLine}"
    fi
}

test_dialog_command_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_command_output."
}
