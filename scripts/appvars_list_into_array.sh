#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_list_into_array() {
	local -n _avli_out_="${1}"
	shift
	readarray -t _avli_out_ < <(run_script 'appvars_list' "$@")
}

test_appvars_list_into_array() {
	warn "CI does not test appvars_list_into_array."
}
