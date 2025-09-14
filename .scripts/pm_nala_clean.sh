#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_clean() {
    info "Removing unused packages."
    info "Running: ${C["RunningCommand"]}sudo nala autoremove -y ${NC}"
    sudo nala autoremove -y > /dev/null 2>&1 || fatal "Failed to remove unused packages from apt.\nFailing command: ${C["FailingCommand"]}sudo nala autoremove -y "

    info "Cleaning up package cache."
    info "Running: ${C["RunningCommand"]}sudo nala clean${NC}"
    sudo sudo nala clean > /dev/null 2>&1 || fatal "Failed to cleanup cache from nala.\nFailing command: ${C["FailingCommand"]}sudo nala clean"
}

test_pm_nala_clean() {
    #run_script 'pm_nala_clean'
    warn "CI does not test pm_nala_clean."
}
