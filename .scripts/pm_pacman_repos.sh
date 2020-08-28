#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_pacman_repos() {
    return # All packages needed are in the Arch repos
}

test_pm_pacman_repos() {
    # run_script 'pm_pacman_repos'
    warn "CI does not test pm_pacman_repos."
}
