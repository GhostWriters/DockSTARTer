#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_repos() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Update Repositories"
    notice "Updating repositories. Please be patient, this can take a while."
    local Command=""
    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
        REDIRECT='run_command_dialog "${Title}" "${Command}" "" '
    fi
    info "Updating repositories."
    Command="brew update"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal "Failed to get updates from brew.\nFailing command: ${C["FailingCommand"]}${Command}"
}

test_pm_brew_repos() {
    # run_script 'pm_brew_repos'
    warn "CI does not test pm_brew_repos."
}
