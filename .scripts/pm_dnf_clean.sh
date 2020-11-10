#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_clean() {
    info "Removing unused packages."
    dnf -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from dnf.\nFailing command: ${F[C]}dnf -y autoremove"
    info "Cleaning up package cache."
    dnf -y clean all > /dev/null 2>&1 || fatal "Failed to cleanup cache from dnf.\nFailing command: ${F[C]}dnf -y clean all"
}

test_pm_dnf_clean() {
    # run_script 'pm_dnf_clean'
    warn "CI does not test pm_dnf_clean."
}
