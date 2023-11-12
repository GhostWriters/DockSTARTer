#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_clean() {
    info "Cleaning up package cache."
    sudo pacman -Sc --noconfirm > /dev/null 2>&1 || info "Failed to cleanup pacman cache.\nFailing command: ${F[C]}sudo pacman -Sc --noconfirm"
}

test_pm_pacman_clean() {
    # run_script 'pm_pacman_clean'
    warn "CI does not test pm_pacman_clean."
}
