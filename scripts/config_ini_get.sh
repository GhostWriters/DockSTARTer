#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_ini_get() {
	# config_ini_get [SECTION_KEY] [CONFIG_FILE]
	local result
	run_script 'config_ini_get_into' result "$@" || return 1
	echo "${result}"
}

test_config_ini_get() {
	warn "CI does not test config_ini_get."
}
