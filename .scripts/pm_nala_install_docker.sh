#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_install_docker() {
    # https://docs.docker.com/install/linux/docker-ce/debian/
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    local RemovePackages="containerd docker docker-compose docker-engine docker.io runc"
    local Command="sudo nala remove --no-update -y ${RemovePackages}"
    info "Removing conflicting Docker packages."
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${Command}" &> /dev/null || true

    run_script 'remove_snap_docker'
    run_script 'get_docker'
}

test_pm_nala_install_docker() {
    #run_script 'pm_nala_repos'
    #run_script 'pm_nala_install_docker'
    warn "CI does not test pm_nala_install_docker."
}
