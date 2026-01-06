#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Prefix="appvars_create_"

# shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
unset_needs_appvars_create() {
	return

	if [[ -d ${TIMESTAMPS_FOLDER:?} ]]; then
		rm -f "${TIMESTAMPS_FOLDER:?}/${Prefix}"* &> /dev/null || true
	else
		mkdir "${TIMESTAMPS_FOLDER:?}"
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
	fi

	if [[ $# -gt 0 ]]; then
		for AppName in "$@"; do
			local VarFile
			VarFile="$(run_script 'app_env_file' "${AppName}")"
			if [[ -f ${VarFile} ]]; then
				touch -r "${VarFile}" "${TIMESTAMPS_FOLDER:?}/${Prefix}$(basename "${VarFile}")"
			fi
		done
		return
	fi

	for AppName in $(run_script 'app_list_added'); do
		local VarFile
		VarFile="$(run_script 'app_env_file' "${AppName}")"
		if [[ -f ${VarFile} ]]; then
			touch -r "${VarFile}" "${TIMESTAMPS_FOLDER:?}/${Prefix}$(basename "${VarFile}")"
		fi
	done
}

test_unset_needs_appvars_create() {
	warn "CI does not test unset_needs_appvars_create."
}
