#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_disabled_into_array() {
	local -n _aldis_out_="${1}"
	assert_nameref_is_array "${1}"
	readarray -t _aldis_out_ < <(run_script 'app_list_disabled')
}

test_app_list_disabled_into_array() {
	warn "CI does not test app_list_disabled_into_array."
}
