#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_template_file_into() {
	local -n _atfi_out_="${1}"
	assert_nameref_is_string "${1}"
	local -l _atfi_appname_="${2:-}"
	local _atfi_template_="${3:-}"
	_atfi_out_="${TEMPLATES_FOLDER}/${_atfi_appname_}/${_atfi_template_//"*"/"${_atfi_appname_}"}"
}

test_app_template_file_into() {
	warn "CI does not test app_template_file_into."
}
