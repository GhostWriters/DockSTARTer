#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

env_lines_into_array() {
	local -n _elia_out_="${1}"
	assert_nameref_is_array "${1}"
	shift
	readarray -t _elia_out_ < <(
		run_script 'env_lines' "$@"
	)
}

test_env_lines_into_array() {
	warn "CI does not test env_lines_into_array."
}
