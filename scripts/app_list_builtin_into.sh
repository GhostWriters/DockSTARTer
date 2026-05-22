#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_builtin_into() {
	local -n _albi_out_="${1}"
	readarray -t _albi_out_ < <(run_script 'app_list_builtin')
}

test_app_list_builtin_into() {
	warn "CI does not test app_list_builtin_into."
}
