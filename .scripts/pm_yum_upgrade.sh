#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_upgrade() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages. Please be patient, this can take a while."
        yum -y upgrade > /dev/null 2>&1 || fatal "Failed to upgrade packages from yum."
    fi
}

test_pm_yum_upgrade() {
    # run_script 'pm_yum_upgrade'
    warning "Travis does not test pm_yum_upgrade."
}
