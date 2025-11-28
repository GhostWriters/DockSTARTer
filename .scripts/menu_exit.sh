#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_exit() {
    if run_script 'question_prompt' Y "Do you want to exit ${APPLICATION_NAME}?" "Exit ${APPLICATION_NAME}" "${ASSUMEYES:+Y}"; then
        reset -Q || clear
        info "Exiting ${APPLICATION_NAME}."
        exit 0
    fi
    return 0
}

test_menu_exit() {
    # run_script 'menu_exit'
    warn "CI does not test menu_exit."
}
