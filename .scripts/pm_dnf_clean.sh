#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_clean() {
    info "Removing unused packages and cleaning up package cache."
    dnf -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from dnf."
    dnf -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from dnf."
}

test_pm_dnf_clean() {
    # run_script 'pm_dnf_clean'
    warning "Travis does not test pm_dnf_clean."
}
