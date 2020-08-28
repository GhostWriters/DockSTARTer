#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_pacman_clean() {
    info "Cleaning up package cache."
    pacman -Sc --noconfirm > /dev/null 2>&1 || info "Failed to cleanup pacman cache."
}

test_pm_pacman_clean() {
    # run_script 'pm_pacman_clean'
    warn "CI does not test pm_pacman_clean."
}
