#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_json_get() {
	# config_json_get JqPath ConfigFile
	local result
	run_script 'config_json_get_into' result "$@" || return 1
	printf '%s' "${result}"
}

test_config_json_get() {
	warn "CI does not test config_json_get."
}
