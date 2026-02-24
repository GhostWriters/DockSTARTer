#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/appvars_create"

# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
unset_needs_appvars_create() {
	if [[ ! -d ${timestamps_folder} ]]; then
		mkdir -p "${timestamps_folder}"
		run_script 'set_permissions' "${timestamps_folder}"
	fi

	if [[ $# -eq 0 ]]; then
		# BULK UNSET
		# 1. Record Global .env state
		cp -a "${COMPOSE_ENV}" "${timestamps_folder}/$(basename "${COMPOSE_ENV}")"

		# 2. Record Added Apps List
		run_script 'app_list_added' > "${timestamps_folder}/AddedApps"

		# 3. Create LastSynced sentinel
		touch "${timestamps_folder}/LastSynced"
		return
	fi

	# PRECISE UNSET
	for AppName in "$@"; do
		local -u APPNAME=${AppName^^}
		touch "${timestamps_folder}/LastSynced_${APPNAME}"
		# Also update the app env timestamp if it exists
		local AppEnvFile
		AppEnvFile="$(run_script 'app_env_file' "${AppName}")"
		if [[ -f ${AppEnvFile} ]]; then
			cp -a "${AppEnvFile}" "${timestamps_folder}/$(basename "${AppEnvFile}")"
		fi
	done
}

test_unset_needs_appvars_create() {
	warn "CI does not test unset_needs_appvars_create."
}
