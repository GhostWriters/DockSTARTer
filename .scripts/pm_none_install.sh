#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_none_install() {
    info "Package manager '${C["UserCommand"]}none${NC}' does not install dependencies."
}

test_pm_none_install() {
    # run_script 'pm_none_repos'
    # run_script 'pm_none_install'
    warn "CI does not test pm_none_install."
}
