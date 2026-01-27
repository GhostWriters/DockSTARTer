#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

remove_snap_docker() {
	if [[ -n "$(command -v snap)" ]]; then
		if snap services docker &> /dev/null; then
			info "Removing snap Docker package."
			local Command="sudo snap remove docker"
			notice "Running: ${C["RunningCommand"]}${Command}${NC}"
			eval "${Command}" &> /dev/null || true
		fi
	fi
}

test_remove_snap_docker() {
	run_script 'remove_snap_docker'
}
