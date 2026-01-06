#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_zypper_repos() {
	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	notice "Updating repositories. Please be patient, this can take a while."
	local COMMAND=""
	COMMAND="sudo zypper -n refresh"
	info "Updating repositories."
	notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
	eval "${REDIRECT}${COMMAND}" ||
		fatal \
			"Failed to get updates from zypper." \
			"Failing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_zypper_repos() {
	# run_script 'pm_zypper_repos'
	warn "CI does not test pm_zypper_repos."
}
