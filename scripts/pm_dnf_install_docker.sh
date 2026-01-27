#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_install_docker() {
	# https://docs.docker.com/install/linux/docker-ce/fedora/
	local RemovePackages="docker-client docker-client-latest docker-common docker-compose docker-engine docker-engine-selinux docker-latest docker-latest-logrotate docker-logrotate docker-selinux"
	info "Removing conflicting Docker packages."
	local Command="sudo dnf -y remove ${RemovePackages}"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${Command}" &> /dev/null || true
	run_script 'remove_snap_docker'
	run_script 'get_docker'
}

test_pm_dnf_install_docker() {
	# run_script 'pm_dnf_repos'
	# run_script 'pm_dnf_install_docker'
	warn "CI does not test pm_dnf_install_docker."
}
