#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_install_docker() {
    warn "brew does not currently install docker."
}

test_pm_brew_install_docker() {
    warn "CI does not test pm_brew_install_docker."
}
