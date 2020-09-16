#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_pacman_install() {
    info "Installing dependencies."
    pacman -Sy --noconfirm curl git grep libnewt sed > /dev/null 2>&1 || fatal "Failed to install dependencies using pacman."
}

test_pm_pacman_install() {
    # run_script 'pm_pacman_install'
    warn "CI does not test pm_pacman_install."
}
