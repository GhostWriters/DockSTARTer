#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local COMMAND='sudo nala full-upgrade -y'
        local REDIRECT='> /dev/null 2>&1 '
        if run_script 'question_prompt' Y "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
        fi
        notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
        eval "${REDIRECT}${COMMAND}" ||
            fatal "Failed to upgrade packages from nala.\nFailing command: ${C["FailingCommand"]}${COMMAND}"
    fi
}

test_pm_nala_upgrade() {
    #run_script 'pm_nala_upgrade'
    warn "CI does not test pm_nala_upgrade."
}
