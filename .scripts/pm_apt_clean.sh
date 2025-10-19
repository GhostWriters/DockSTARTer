#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_clean() {
    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    local Command
    info "Removing unused packages."
    Command="sudo apt-get -y autoremove"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        warn \
            "Failed to remove unused packages from apt.\n" \
            "Failing command: ${C["FailingCommand"]}${Command}"

    info "Cleaning up package cache."
    Command="sudo apt-get -y autoclean"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        warn \
            "Failed to cleanup cache from apt.\n" \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

test_pm_apt_clean() {
    run_script 'pm_apt_clean'
}
