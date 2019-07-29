#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_upgrade() {
    if [[ ${CI:-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT="> /dev/null 2>&1"
        if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-}" N "Would you like to display the command output?"; then
            REDIRECT=""
        fi
        eval apt-get -y dist-upgrade "${REDIRECT}" || fatal "Failed to upgrade packages from apt."
    fi
}

test_pm_apt_upgrade() {
    run_script 'pm_apt_upgrade'
}
