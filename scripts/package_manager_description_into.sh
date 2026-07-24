#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_description_into() {
	local -n _pmdi_out_="${1}"
	assert_nameref_is_string "${1}"
	local -l _pmdi_pm_="${2-}"
	if ! run_script 'package_manager_is_valid' "${_pmdi_pm_}"; then
		_pmdi_out_="${_pmdi_pm_^}"
	else
		_pmdi_out_="${PM_DESCRIPTION["${_pmdi_pm_}"]}"
	fi
}

test_package_manager_description_into() {
	warn "CI does not test package_manager_description_into."
}
