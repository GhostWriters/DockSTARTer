#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

sanitize_path() {
	local result
	run_script 'sanitize_path_into' result "${1-}"
	printf '%s\n' "${result}"
}
test_sanitize_path() {
	warn "CI does not test menu_app_select."
}
