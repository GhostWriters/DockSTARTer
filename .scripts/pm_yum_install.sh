#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_install() {
    info "Installing dependencies."
    yum -y install curl git grep newt sed > /dev/null 2>&1 || fatal "Failed to install dependencies from yum."
}

test_pm_yum_install() {
    # run_script 'pm_yum_install'
    warn "CI does not test pm_yum_install."
}
