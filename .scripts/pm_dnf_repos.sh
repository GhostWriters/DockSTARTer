#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_repos() {
    info "dnf does not require additional repositories."
}

test_pm_dnf_repos() {
    # run_script 'pm_dnf_repos'
    warn "CI does not test pm_dnf_repos."
}
