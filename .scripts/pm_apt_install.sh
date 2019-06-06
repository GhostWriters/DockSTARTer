#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_apt_install() {
    info "Installing dependencies."
    apt-get -y install apt-transport-https curl git grep python3 python3-pip rsync sed whiptail > /dev/null 2>&1 || fatal "Failed to install dependencies from apt."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    apt-get -y install build-essential libssl-dev libffi-dev python3-dev > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from apt."
}

test_pm_apt_install() {
    run_script 'pm_apt_install'
}
