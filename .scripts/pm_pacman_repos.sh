#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_repos() {
    info "pacman does not require additional repositories."
}

test_pm_pacman_repos() {
    # run_script 'pm_pacman_repos'
    warn "CI does not test pm_pacman_repos."
}
