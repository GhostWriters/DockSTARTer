#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_upgrade() {
    local Title="Upgrade Packages"
    if [[ ${CI-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT="> /dev/null 2>&1"
        if run_script 'question_prompt' N "Would you like to display the command output?" "${Title}" "${VERBOSE:+Y}"; then
            REDIRECT=""
        fi
        eval "sudo apk upgrade ${REDIRECT}" || fatal "Failed to upgrade packages from apk.\nFailing command: ${F[C]}sudo apk upgrade"
    fi
}

test_pm_apk_upgrade() {
    # run_script 'pm_apk_upgrade'
    warn "CI does not test pm_apk_upgrade."
}
