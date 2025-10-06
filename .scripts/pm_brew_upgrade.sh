#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_upgrade() {
    #shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT='&> /dev/null '
        if [[ -n ${VERBOSE-} ]]; then
            #shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
            REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
        fi
        for Command in "brew cask upgrade" "brew upgrade"; do
            notice "Running: ${C["RunningCommand"]}${Command}${NC}"
            eval "${REDIRECT}${Command}" ||
                fatal "Failed to upgrade packages from brew.\nFailing command: ${C["FailingCommand"]}${Command}"
        done
    fi
}

test_pm_brew_upgrade() {
    warn "CI does not test pm_brew_upgrade."
}
