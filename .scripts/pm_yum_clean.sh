#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_clean() {
    info "Removing unused packages."
    yum -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from yum."
    info "Cleaning up package cache."
    yum -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from yum."
}

test_pm_yum_clean() {
    # run_script 'pm_yum_clean'
    warn "CI does not test pm_yum_clean."
}
