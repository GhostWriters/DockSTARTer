#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_install() {
    info "Installing dependencies."
    apt-get -y install apt-transport-https curl git grep sed whiptail > /dev/null 2>&1 || fatal "Failed to install dependencies from apt.\nFailing command: ${F[C]}apt-get -y install apt-transport-https curl git grep sed whiptail"
}

test_pm_apt_install() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install'
}
