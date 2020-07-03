#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_install() {
    info "Installing dependencies."
    dnf -y install curl git grep newt sed > /dev/null 2>&1 || fatal "Failed to install dependencies from dnf."
}

test_pm_dnf_install() {
    # run_script 'pm_dnf_install'
    warn "CI does not test pm_dnf_install."
}
