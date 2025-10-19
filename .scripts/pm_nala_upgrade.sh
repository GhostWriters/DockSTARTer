#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_upgrade() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    local COMMAND='sudo nala upgrade --no-update --full -y'
    notice "Upgrading packages. Please be patient, this can take a while."
    notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
    eval "${REDIRECT}${COMMAND}" ||
        fatal \
            "Failed to upgrade packages from nala.\n" \
            "Failing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_nala_upgrade() {
    #run_script 'pm_nala_upgrade'
    warn "CI does not test pm_nala_upgrade."
}
