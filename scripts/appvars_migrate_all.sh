#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_migrate_all() {
	run_script 'appvars_migrate_enabled_lines'
	local ENABLED_APPS
	ENABLED_APPS=$(run_script 'app_list_enabled')
	for APPNAME in ${ENABLED_APPS-}; do
		run_script 'appvars_migrate' "${APPNAME}"
	done
}

test_appvars_migrate_all() {
	# run_script 'appvars_migrate_all'
	warn "CI does not test appvars_migrate_all."
}
