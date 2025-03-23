#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT="> /dev/null 2>&1"
        if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-$PROMPT_DEFAULT}" N "Would you like to display the command output?" "${Title}"; then
            REDIRECT=""
        fi
        eval "sudo pacman -Syu --noconfirm ${REDIRECT}" || fatal "Failed to upgrade packages from pacman.\nFailing command: ${F[C]}sudo pacman -Syu --noconfirm"
    fi
}

test_pm_pacman_upgrade() {
    # run_script 'pm_pacman_upgrade'
    warn "CI does not test pm_pacman_upgrade."
}
