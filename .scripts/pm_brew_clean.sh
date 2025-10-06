#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_clean() {
    info "Removing unused packages."
    notice "Running: ${C["RunningCommand"]}brew autoremove${NC}"
    brew autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from brew.\nFailing command: ${C["FailingCommand"]}brew autoremove"
    info "Cleaning up package cache."
    notice "Running: ${C["RunningCommand"]}brew cleanup${NC}"
    brew cleanup > /dev/null 2>&1 || fatal "Failed to cleanup cache from brew.\nFailing command: ${C["FailingCommand"]}brew cleanup"
}

test_pm_brew_clean() {
    warn "CI does not test pm_brew_clean."
}
