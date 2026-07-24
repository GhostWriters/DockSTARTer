#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_all() {
	run_script 'appvars_migrate_enabled_lines'
	local -a EnabledApps
	run_script 'app_list_enabled_into_array' EnabledApps
	for APPNAME in "${EnabledApps[@]-}"; do
		run_script 'appvars_migrate' "${APPNAME}"
	done
}

test_appvars_migrate_all() {
	# run_script 'appvars_migrate_all'
	warn "CI does not test appvars_migrate_all."
}
