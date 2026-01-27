#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_clean() {
	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	local Command
	info "Removing unused packages."
	Command="brew autoremove"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		warn \
			"Failed to remove unused packages from brew." \
			"Failing command: ${C["FailingCommand"]}${Command}"

	info "Cleaning up package cache."
	Command="brew cleanup"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		warn \
			"Failed to cleanup cache from brew." \
			"Failing command: ${C["FailingCommand"]}${Command}"
}

test_pm_brew_clean() {
	warn "CI does not test pm_brew_clean."
}
