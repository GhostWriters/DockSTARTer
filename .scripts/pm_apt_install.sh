#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install() {
    local Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local COMMAND=""
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        if use_dialog_box; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='|& dialog_pipe "${Title}" "${COMMAND}"'
        else
            REDIRECT=""
        fi
    fi
    COMMAND="sudo apt-get -y install curl dialog git grep sed"
    eval "${COMMAND} ${REDIRECT}" || fatal "Failed to install dependencies from apt.\nFailing command: ${F[C]}${COMMAND}"
}

test_pm_apt_install() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install'
}
