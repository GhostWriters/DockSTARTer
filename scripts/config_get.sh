#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_get() {
	# config_get section_key [config_file]
	local result
	run_script 'config_get_into' result "$@" || return 1
	echo "${result}"
}

test_config_get() {
	warn "CI does not test config_get."
}
