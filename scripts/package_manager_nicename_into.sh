#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

package_manager_nicename_into() {
	local -n _pmni_out_="${1}"
	assert_nameref_is_string "${1}"
	local -l _pmni_pm_="${2-}"
	if ! run_script 'package_manager_is_valid' "${_pmni_pm_}"; then
		_pmni_out_="${_pmni_pm_^}"
	else
		_pmni_out_="${PM_NICENAME["${_pmni_pm_}"]}"
	fi
}

test_package_manager_nicename_into() {
	warn "CI does not test package_manager_nicename_into."
}
