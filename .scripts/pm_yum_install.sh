#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_install() {
    info "Installing dependencies."
    yum -y install curl git grep newt python3 python3-pip rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from yum."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    info "Installing python dependencies."
    yum -y install redhat-rpm-config gcc libffi-devel python3-devel openssl-devel > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from yum."
}

test_pm_yum_install() {
    # run_script 'pm_yum_install'
    warn "CI does not test pm_yum_install."
}
