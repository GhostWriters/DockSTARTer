#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_upgrade() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    local COMMAND='sudo apt-get -y dist-upgrade'
    notice "Upgrading packages. Please be patient, this can take a while."
    notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
    eval "${REDIRECT}${COMMAND}" ||
        fatal \
            "Failed to upgrade packages from apt.\n" \
            "Failing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_apt_upgrade() {
    run_script 'pm_apt_upgrade'
}
