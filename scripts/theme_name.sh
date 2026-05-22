#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name() {
	local result
	run_script 'theme_name_into' result
	echo "${result}"
}

test_theme_name() {
	run_script 'config_theme'
	run_script 'theme_name'
}
