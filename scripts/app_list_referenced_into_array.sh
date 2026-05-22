#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_referenced_into_array() {
	local -n _alri_out_="${1}"
	readarray -t _alri_out_ < <(run_script 'app_list_referenced')
}

test_app_list_referenced_into_array() {
	warn "CI does not test app_list_referenced_into_array."
}
