#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_nicename_from_template_into_array() {
	local -n _anftia_out_="${1}"
	shift
	_anftia_out_=()
	local _anftia_name_
	for _anftia_app_ in "$@"; do
		run_script 'app_nicename_from_template_into' _anftia_name_ "${_anftia_app_}"
		_anftia_out_+=("${_anftia_name_}")
	done
}

test_app_nicename_from_template_into_array() {
	warn "CI does not test app_nicename_from_template_into_array."
}
