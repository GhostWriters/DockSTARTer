#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_repos() {
    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    notice "Updating repositories. Please be patient, this can take a while."
    local Command="brew update"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal \
            "Failed to get updates from brew." \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

test_pm_brew_repos() {
    # run_script 'pm_brew_repos'
    warn "CI does not test pm_brew_repos."
}
