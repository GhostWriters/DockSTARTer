#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_dialog_example() {
    local Title=${1-}
    dialog_success "${Title}"
    echo -n "${BS}"
}

test_menu_dialog_example() {
    warn "CI does not test theme_exists."
}
