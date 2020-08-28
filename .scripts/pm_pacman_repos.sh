#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_pacman_repos() {
    info "This script does not manage pacman repositories for you. All packages needed should be in the default Arch repos."
}

test_pm_pacman_repos() {
    # run_script 'pm_pacman_repos'
    warn "CI does not test pm_pacman_repos."
}
