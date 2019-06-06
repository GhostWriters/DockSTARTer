#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_upgrade() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages. Please be patient, this can take a while."
        dnf -y upgrade --refresh > /dev/null 2>&1 || fatal "Failed to upgrade packages from dnf."
    fi
}

test_pm_dnf_upgrade() {
    # run_script 'pm_dnf_upgrade'
    warning "Travis does not test pm_dnf_upgrade."
}
