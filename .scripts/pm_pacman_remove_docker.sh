#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_pacman_remove_docker() {
    info "This script does not install or remove docker with pacman. You will need to do this manually."
}

test_pm_pacman_remove_docker() {
    # run_script 'pm_pacman_remove_docker'
    warn "CI does not test pm_pacman_remove_docker."
}
