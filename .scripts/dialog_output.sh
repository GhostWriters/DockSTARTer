#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

dialog_output() {
    local Title=${1:-}
    local SubTitle=${2:-}
    local TimeOut=${3:-0}
    #dialog --title "dialog_output" --msgbox "Title=${Title}\nSubTitle=${SubTitle}\nTimeOut=${TimeOut}\n" 0 0
    dialog --begin 2 2 --timeout "${TimeOut}" --title "${Title}" --programbox "${SubTitle}" $((LINES - 4)) $((COLUMNS - 5))
}

test_dialog_output() {
    # run_script 'dialog_output'
    warn "CI does not test dialog_output."
}
