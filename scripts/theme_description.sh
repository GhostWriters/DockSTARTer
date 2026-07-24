#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_description() {
	local result
	run_script 'theme_description_into' result "${1-}"
	printf '%s\n' "${result}"
}

test_theme_description() {
	run_script 'config_theme'
	run_script 'theme_description'
}
