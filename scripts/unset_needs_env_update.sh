#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/env_update"

unset_needs_env_update() {
	local VarFile=${1-}

	if [[ -z ${VarFile} ]]; then
		run_script 'unset_needs_env_update' "${COMPOSE_ENV}"
		for AppName in $(run_script 'app_list_referenced'); do
			run_script 'unset_needs_env_update' "$(run_script 'app_env_file' "${AppName}")"
		done
		return
	fi

	if [[ ! -d ${timestamps_folder} ]]; then
		mkdir "${timestamps_folder}"
		run_script 'set_permissions' "${timestamps_folder}"
	fi

	local filename
	filename="$(basename "${VarFile}")"

	rm -f "${timestamps_folder}/${filename}"* &> /dev/null || true

	cp -a "${VarFile}" "${timestamps_folder}/${filename}"
	if [[ ${VarFile} == "${COMPOSE_ENV}" ]]; then
		local ReferencedAppsFile
		ReferencedAppsFile="${timestamps_folder}/${filename}_ReferencedApps"
		run_script 'app_list_referenced' > "${ReferencedAppsFile}"
	else
		local -u APPNAME
		APPNAME="$(run_script 'varfile_to_appname' "${VarFile}")"
		local AppEnabledFile
		AppEnabledFile="${timestamps_folder}/${filename}_${APPNAME}__ENABLED"
		run_script 'env_get_line' "${APPNAME}__ENABLED" > "${AppEnabledFile}"
		# Record the state of the global .env for this specific app
		cp -a "${COMPOSE_ENV}" "${timestamps_folder}/${filename}_$(basename "${COMPOSE_ENV}")"
	fi
}

test_unset_needs_env_update() {
	warn "CI does not test unset_needs_env_update."
}
