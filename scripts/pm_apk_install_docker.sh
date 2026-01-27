#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apk_install_docker() {
	#shellcheck disable=SC2034 #(warning): Title appears unused. Verify use (or export if used externally).
	Title="Install Docker"
	notice "Installing docker. Please be patient, this can take a while."
	local COMMAND='sudo apk add docker docker-cli-compose'
	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		#shellcheck disable=SC2016 # (info): Expressions don't expand in single quotes, use double quotes for that.
		REDIRECT='run_command_dialog "${Title}" "${COMMAND}" "" '
	fi
	eval "${REDIRECT}${COMMAND}" ||
		fatal \
			"Failed to install docker and docker-compose using apk." \
			"Failing command: ${C["FailingCommand"]}${COMMAND}"
}

test_pm_apk_install_docker() {
	# run_script 'pm_apk_repos'
	# run_script 'pm_apk_install_docker'
	warn "CI does not test pm_apk_install_docker."
}
