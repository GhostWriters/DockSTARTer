#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_install() {
    local Title="Install Dependencies"
    notice "Installing dependencies. Please be patient, this can take a while."
    local COMMAND=""
    local REDIRECT="> /dev/null 2>&1"
    if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
    fi
    COMMAND='sudo apk add coreutils curl dialog git grep openrc sed'
    eval "${REDIRECT}${COMMAND}" || fatal "Failed to install dependencies from apk.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_apk_install() {
    # run_script 'pm_apk_repos'
    # run_script 'pm_apk_install'
    warn "CI does not test pm_apk_install."
}
