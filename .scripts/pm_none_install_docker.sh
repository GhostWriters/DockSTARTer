#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_none_install_docker() {
    info "Package manager '${C["UserCommand"]}none${NC}' does not install docker."
}

test_pm_none_install_docker() {
    # run_script 'pm_none_repos'
    # run_script 'pm_none_install_docker'
    warn "CI does not test pm_none_install_docker."
}
