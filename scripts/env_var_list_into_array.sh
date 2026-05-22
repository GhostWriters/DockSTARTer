#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_var_list_into_array() {
	local -n _evli_out_="${1}"
	shift
	readarray -t _evli_out_ < <(run_script 'env_var_list' "$@")
}

test_env_var_list_into_array() {
	warn "CI does not test env_var_list_into_array."
}
