#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_filter_runnable_into_array() {
	local -n _afri_out_="${1}"
	assert_nameref_is_array "${1}"
	shift
	_afri_out_=()
	for _afri_app_ in "$@"; do
		local -l _afri_base_
		run_script 'appname_to_baseappname_into' _afri_base_ "${_afri_app_}"
		local _afri_main_yml_="${TEMPLATES_FOLDER}/${_afri_base_}/${_afri_base_}.yml"
		local _afri_arch_yml_="${TEMPLATES_FOLDER}/${_afri_base_}/${_afri_base_}.${ARCH}.yml"
		if [[ -f ${_afri_main_yml_} && -f ${_afri_arch_yml_} ]]; then
			_afri_out_+=("${_afri_app_}")
		fi
	done
}

test_app_filter_runnable_into_array() {
	warn "CI does not test app_filter_runnable_into_array."
}
