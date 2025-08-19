#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local COMMAND='sudo pacman -Syu --noconfirm'
        local REDIRECT='> /dev/null 2>&1 '
        if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
        fi
        eval "${REDIRECT}${COMMAND}" || fatal "Failed to upgrade packages from pacman.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
    fi
}

test_pm_pacman_upgrade() {
    # run_script 'pm_pacman_upgrade'
    warn "CI does not test pm_pacman_upgrade."
}
