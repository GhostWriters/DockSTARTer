#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_upgrade() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Upgrading packages. Please be patient, this can take a while."
        apt-get -y dist-upgrade > /dev/null 2>&1 || fatal "Failed to upgrade packages from apt."
    fi
}

test_pm_apt_upgrade() {
    run_script 'pm_apt_upgrade'
}
