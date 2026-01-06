#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_clean() {
	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	local Command
	info "Removing unused packages."
	Command="sudo nala autoremove --no-update -y"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		warn \
			"Failed to remove unused packages from nala." \
			"Failing command: ${C["FailingCommand"]}${Command}"

	info "Cleaning up package cache."
	Command="sudo nala clean"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		warn \
			"Failed to cleanup cache from nala." \
			"Failing command: ${C["FailingCommand"]}${Command}"
}

test_pm_nala_clean() {
	#run_script 'pm_nala_clean'
	warn "CI does not test pm_nala_clean."
}
