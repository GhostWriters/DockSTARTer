#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install() {
    local Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local COMMAND=""
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
    fi
    COMMAND='sudo pacman -Sy --noconfirm curl dialog git grep sed'
    eval "${REDIRECT}${COMMAND}" || fatal "Failed to install dependencies from pacman.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_pacman_install() {
    # run_script 'pm_pacman_repos'
    # run_script 'pm_pacman_install'
    warn "CI does not test pm_pacman_install."
}
