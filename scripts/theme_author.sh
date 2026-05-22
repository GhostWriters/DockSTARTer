#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_author() {
	local result
	run_script 'theme_author_into' result "${1-}"
	printf '%s\n' "${result}"
}

test_theme_author() {
	run_script 'config_theme'
	run_script 'theme_author'
}
