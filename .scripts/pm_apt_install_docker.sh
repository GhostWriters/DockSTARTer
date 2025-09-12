#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install_docker() {
    # https://docs.docker.com/install/linux/docker-ce/debian/
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    local RemovePackages="containerd docker docker-compose docker-engine docker.io runc"
    info "Removing conflicting Docker packages."
    local Command="sudo apt-get -y remove ${RemovePackages}"
    info "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${Command}" > /dev/null 2>&1 || true
    run_script 'remove_snap_docker'
    run_script 'get_docker'
}

test_pm_apt_install_docker() {
    run_script 'pm_apt_repos'
    run_script 'pm_apt_install_docker'
}
