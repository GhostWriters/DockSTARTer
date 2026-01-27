#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

declare MINIMUM_DOCKER="20.10.0"
declare MINIMUM_COMPOSE="2.3.0"

needs_install_docker() {
	if [[ -n ${FORCE-} ]]; then
		return 0
	fi

	# Find minimum compatible version at https://docs.docker.com/engine/release-notes/
	# Note compatibility from https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0
	local INSTALLED_DOCKER INSTALLED_COMPOSE
	INSTALLED_DOCKER=$( (docker --version 2> /dev/null | ${GREP} --color=never -Po "Docker version \K([0-9][a-zA-Z0-9_.-]*)") || echo "0")
	INSTALLED_COMPOSE=$( (docker compose version 2> /dev/null | ${GREP} --color=never -Po "Docker Compose version v\K([0-9][a-zA-Z0-9_.-]*)") || echo "0")

	vergt "${MINIMUM_DOCKER}" "${INSTALLED_DOCKER:-0}" || vergt "${MINIMUM_COMPOSE}" "${INSTALLED_COMPOSE:-0}"
}

test_needs_install_docker() {
	warn "CI does not test needs_install_docker."
}
