#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Prefix="env_update_"

unset_needs_env_update() {
	local VarFile=${1-}

	if [[ -z ${VarFile} ]]; then
		run_script 'unset_needs_env_update' "${COMPOSE_ENV}"
		for AppName in $(run_script 'app_list_referenced'); do
			run_script 'unset_needs_env_update' "$(run_script 'app_env_file' "${AppName}")"
		done
		return
	fi

	if [[ ! -d ${TIMESTAMPS_FOLDER:?} ]]; then
		mkdir "${TIMESTAMPS_FOLDER:?}"
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
	fi

	local filename
	filename="$(basename "${VarFile}")"

	rm -f "$(timestamp_file "${filename}")"* &> /dev/null || true

	touch -r "${VarFile}" "$(timestamp_file "${filename}")"
	if [[ ${VarFile} == "${COMPOSE_ENV}" ]]; then
		local ReferencedAppsFile
		ReferencedAppsFile="$(timestamp_file "${filename}_ReferencedApps")"
		run_script 'app_list_referenced' > "${ReferencedAppsFile}"
	else
		local -u APPNAME
		APPNAME="$(run_script 'varfile_to_appname' "${VarFile}")"
		local AppEnabledFile
		AppEnabledFile="$(timestamp_file "${filename}_${APPNAME}__ENABLED")"
		run_script 'env_get_line' "${APPNAME}__ENABLED" > "${AppEnabledFile}"
	fi
}

timestamp_file() {
	printf "${TIMESTAMPS_FOLDER:?}/${Prefix}%s\n" "$1"
}

test_unset_needs_env_update() {
	warn "CI does not test unset_needs_env_update."
}
