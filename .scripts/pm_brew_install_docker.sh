#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_install_docker() {
    warn "Package manager '${C["UserCommand"]}brew${NC}' does not install docker."
}

test_pm_brew_install_docker() {
    warn "CI does not test pm_brew_install_docker."
}
