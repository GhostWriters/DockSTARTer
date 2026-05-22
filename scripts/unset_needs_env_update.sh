#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare timestamps_folder="${TIMESTAMPS_FOLDER:?}/env_update"

unset_needs_env_update() {
	local VarFile=${1-}

	if [[ -z ${VarFile} ]]; then
		run_script 'unset_needs_env_update' "${COMPOSE_ENV}"
		local -a ReferencedApps
		run_script 'app_list_referenced_into_array' ReferencedApps
		for AppName in "${ReferencedApps[@]-}"; do
			local AppEnvFile
			run_script 'app_env_file_into' AppEnvFile "${AppName}"
			run_script 'unset_needs_env_update' "${AppEnvFile}"
		done
		return
	fi

	if [[ ! -d ${timestamps_folder} ]]; then
		mkdir -p "${timestamps_folder}"
		run_script 'set_permissions' "${timestamps_folder}"
	fi

	local filename
	filename="$(basename "${VarFile}")"

	rm -f "${timestamps_folder}/${filename}"* &> /dev/null || true

	cp -a "${VarFile}" "${timestamps_folder}/${filename}"
	if [[ ${VarFile} == "${COMPOSE_ENV}" ]]; then
		local ReferencedAppsFile
		ReferencedAppsFile="${timestamps_folder}/${filename}_ReferencedApps"
		local -a ReferencedApps
		run_script 'app_list_referenced_into_array' ReferencedApps
		printf '%s\n' "${ReferencedApps[@]-}" > "${ReferencedAppsFile}"
	else
		local -u APPNAME
		run_script 'varfile_to_appname_into' APPNAME "${VarFile}"
		local AppEnabledFile
		AppEnabledFile="${timestamps_folder}/${filename}_${APPNAME}__ENABLED"
		local EnabledLine
		run_script 'env_get_line_into' EnabledLine "${APPNAME}__ENABLED"
		echo "${EnabledLine}" > "${AppEnabledFile}"
		# Record the state of the global .env for this specific app
		cp -a "${COMPOSE_ENV}" "${timestamps_folder}/${filename}_$(basename "${COMPOSE_ENV}")"
	fi
}

test_unset_needs_env_update() {
	warn "CI does not test unset_needs_env_update."
}
