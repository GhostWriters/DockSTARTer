#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_upgrade() {
    if [[ ${CI:-} != true ]]; then
        notice "Upgrading packages. Please be patient, this can take a while."
        local REDIRECT="> /dev/null 2>&1"
        if [[ -n ${VERBOSE:-} ]] || run_script 'question_prompt' "${PROMPT:-}" N "Would you like to display the command output?"; then
            REDIRECT=""
        fi
        eval dnf -y upgrade --refresh "${REDIRECT}" || fatal "Failed to upgrade packages from dnf."
    fi
}

test_pm_dnf_upgrade() {
    # run_script 'pm_dnf_upgrade'
    warn "CI does not test pm_dnf_upgrade."
}
