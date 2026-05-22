#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_added_into() {
	local -n _alai_out_="${1}"
	readarray -t _alai_out_ < <(run_script 'app_list_added')
}

test_app_list_added_into() {
	warn "CI does not test app_list_added_into."
}
