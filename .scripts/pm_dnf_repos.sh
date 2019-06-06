#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_repos() {
    info "dnf does not require additional repositories."
}

test_pm_dnf_repos() {
    # run_script 'pm_dnf_repos'
    warning "Travis does not test pm_dnf_repos."
}
