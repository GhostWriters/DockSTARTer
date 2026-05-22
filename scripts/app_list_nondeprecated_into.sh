#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_nondeprecated_into() {
	local -n _alndep_out_="${1}"
	readarray -t _alndep_out_ < <(run_script 'app_list_nondeprecated')
}

test_app_list_nondeprecated_into() {
	warn "CI does not test app_list_nondeprecated_into."
}
