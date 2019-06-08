#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_clean() {
    info "Removing unused packages and cleaning up package cache."
    apt-get -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from apt."
    apt-get -y autoclean > /dev/null 2>&1 || fatal "Failed to cleanup cache from apt."
}

test_pm_apt_clean() {
    run_script 'pm_apt_clean'
}
