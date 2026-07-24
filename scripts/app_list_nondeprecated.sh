#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_nondeprecated() {
	local -a BuiltinApps
	run_script 'app_list_builtin_into_array' BuiltinApps
	for APPNAME in "${BuiltinApps[@]-}"; do
		if run_script 'app_is_nondeprecated' "${APPNAME}"; then
			echo "${APPNAME}"
		fi
	done
}

test_app_list_nondeprecated() {
	run_script 'app_list_nondeprecated'
	# warn "CI does not test app_list_nondeprecated."
}
