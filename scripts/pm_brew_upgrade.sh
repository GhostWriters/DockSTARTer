#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_brew_upgrade() {
	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	notice "Upgrading packages. Please be patient, this can take a while."
	for Command in "brew upgrade --cask" "brew upgrade"; do
		notice "Running: ${C["RunningCommand"]}${Command}${NC}"
		eval "${REDIRECT}${Command}" ||
			fatal \
				"Failed to upgrade packages from brew." \
				"Failing command: ${C["FailingCommand"]}${Command}"
	done
}

test_pm_brew_upgrade() {
	warn "CI does not test pm_brew_upgrade."
}
