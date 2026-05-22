#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_heading() {
	local result
	run_script 'menu_heading_into' result "$@"
	printf '%s' "${result}"
}

test_menu_heading() {
	run_script 'config_theme'
	notice WATCHTOWER:
	run_script 'menu_heading' WATCHTOWER
	notice "WATCHTOWER WATCHTOWER__ENABLED:"
	run_script 'menu_heading' WATCHTOWER WATCHTOWER__ENABLED
	notice "'' DOCKER_VOLUME_STORAGE:"
	run_script 'menu_heading' '' DOCKER_VOLUME_STORAGE
	notice ":"
	run_script 'menu_heading'
	warn "CI does not test app_is_nondeprecated."
}
