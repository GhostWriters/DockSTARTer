#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_zypper_install_docker() {
	notice "Installing docker. Please be patient, this can take a while."
	local Command="sudo zypper -n install docker docker-compose"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${Command}" &> /dev/null || true
}

test_pm_zypper_install_docker() {
	# run_script 'pm_zypper_repos'
	# run_script 'pm_zypper_install_docker'
	warn "CI does not test pm_zypper_install_docker."
}
