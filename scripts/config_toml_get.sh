#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_toml_get() {
	# config_toml_get [SECTION_KEY] [CONFIG_FILE]
	local result
	run_script 'config_toml_get_into' result "$@" || return 1
	echo "${result}"
}

test_config_toml_get() {
	warn "CI does not test config_toml_get."
}
