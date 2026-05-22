#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_deprecated_into() {
	local -n _aldep_out_="${1}"
	readarray -t _aldep_out_ < <(run_script 'app_list_deprecated')
}

test_app_list_deprecated_into() {
	warn "CI does not test app_list_deprecated_into."
}
