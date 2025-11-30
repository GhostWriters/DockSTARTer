#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_clean() {
    info "Removing unused packages."
    sudo yum -y autoremove &> /dev/null ||
        warn \
            "Failed to remove unused packages from yum." \
            "Failing command: ${C["FailingCommand"]}sudo yum -y autoremove"

    info "Cleaning up package cache."
    sudo yum -y clean all &> /dev/null ||
        warn \
            "Failed to cleanup cache from yum." \
            "Failing command: ${C["FailingCommand"]}sudo yum -y clean all"
}

test_pm_yum_clean() {
    # run_script 'pm_yum_clean'
    warn "CI does not test pm_yum_clean."
}
