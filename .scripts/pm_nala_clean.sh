#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_clean() {
    info "Removing unused packages."
    notice "Running: ${C["RunningCommand"]}sudo nala autoremove --no-update -y ${NC}"
    sudo nala autoremove --no-update -y > /dev/null 2>&1 || fatal "Failed to remove unused packages from apt.\nFailing command: ${C["FailingCommand"]}sudo nala autoremove --no-update -y "

    info "Cleaning up package cache."
    notice "Running: ${C["RunningCommand"]}sudo nala clean${NC}"
    sudo nala clean > /dev/null 2>&1 || fatal "Failed to cleanup cache from nala.\nFailing command: ${C["FailingCommand"]}sudo nala clean"
}

test_pm_nala_clean() {
    #run_script 'pm_nala_clean'
    warn "CI does not test pm_nala_clean."
}
