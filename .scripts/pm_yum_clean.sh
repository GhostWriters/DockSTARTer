#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_clean() {
    info "Removing unused packages and cleaning up package cache."
    yum -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from yum."
    yum -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from yum."
}

test_pm_yum_clean() {
    # run_script 'pm_yum_clean'
    warning "Travis does not test pm_yum_clean."
}
