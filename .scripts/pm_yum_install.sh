#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_install() {
    info "Installing dependencies."
    yum -y install curl git grep newt python36u python36u-pip rsync sed > /dev/null 2>&1 || fatal "Failed to install dependencies from yum."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    yum -y install redhat-rpm-config gcc libffi-devel python36u-devel openssl-devel > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from yum."
}

test_pm_yum_install() {
    # run_script 'pm_yum_install'
    warning "Travis does not test pm_yum_install."
}
