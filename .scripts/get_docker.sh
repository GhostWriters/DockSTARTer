#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

get_docker() {
	Title="Install Docker"
	if [[ -n ${VERBOSE-} ]]; then
		if use_dialog_box; then
			{
				notice "Installing docker. Please be patient, this can take a while."
				command_get_docker
			} |& dialog_pipe "${Title}" "Installing docker. Please be patient, this can take a while."
		else
			notice "Installing docker. Please be patient, this can take a while."
			command_get_docker
		fi
	else
		notice "Installing docker. Please be patient, this can take a while."
		command_get_docker &> /dev/null
	fi
}

command_get_docker() {
	# https://github.com/docker/docker-install
	local MKTEMP_GET_DOCKER
	MKTEMP_GET_DOCKER=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_DOCKER.XXXXXXXXXX") ||
		fatal \
			"Failed to create temporary docker install script." \
			"Failing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_GET_DOCKER.XXXXXXXXXX\""
	info "Downloading docker install script."
	RunAndLog notice notice \
		fatal "Failed to get docker install script." \
		curl -fsSL https://get.docker.com -o "${MKTEMP_GET_DOCKER}"

	info "Running docker install script."
	RunAndLog notice "" \
		warn "Failed to install docker." \
		sh "${MKTEMP_GET_DOCKER}"

	info "Removing temporary docker install script."
	RunAndLog notice notice \
		warn "Failed to remove temporary docker install script." \
		rm -f "${MKTEMP_GET_DOCKER}"
}

test_get_docker() {
	run_script 'remove_snap_docker'
	run_script 'get_docker'
	RunAndLog notice notice \
		fatal "Failed to determine docker version." \
		docker --version
	RunAndLog notice notice \
		fatal "Failed to determine docker compose version." \
		docker compose version
}
