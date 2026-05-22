#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_name_into() {
	local -n _tni_out_="${1}"
	local _tni_result_
	run_script 'config_get_into' _tni_result_ ui.theme || true
	_tni_out_="${_tni_result_}"
}

test_theme_name_into() {
	warn "CI does not test theme_name_into."
}
