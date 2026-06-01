#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_nicename_into_array() {
	local -n _ania_out_="${1}"
	assert_nameref_is_array "${1}"
	shift
	_ania_out_=()
	local _ania_name_
	for _ania_app_ in "$@"; do
		run_script 'app_nicename_into' _ania_name_ "${_ania_app_}"
		_ania_out_+=("${_ania_name_}")
	done
}

test_app_nicename_into_array() {
	warn "CI does not test app_nicename_into_array."
}
