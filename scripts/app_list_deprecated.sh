#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_deprecated() {
	local -a BuiltinApps
	run_script 'app_list_builtin_into' BuiltinApps
	for APPNAME in "${BuiltinApps[@]-}"; do
		if run_script 'app_is_deprecated' "${APPNAME}"; then
			echo "${APPNAME}"
		fi
	done
}

test_app_list_deprecated() {
	run_script 'app_list_deprecated'
	# warn "CI does not test app_list_deprecated."
}
