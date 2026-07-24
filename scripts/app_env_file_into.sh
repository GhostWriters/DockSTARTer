#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

app_env_file_into() {
	local -n _aefi_out_="${1}"
	assert_nameref_is_string "${1}"
	local -l _aefi_appname_=${2:-}

	local _aefi_AppEnvFilename_=".env.app.${_aefi_appname_}"
	local _aefi_OldAppEnvFilename_="${_aefi_appname_}.env"
	local _aefi_AppEnvFile_="${COMPOSE_FOLDER}/${_aefi_AppEnvFilename_}"
	local _aefi_OldAppEnvFile_="${APP_ENV_FOLDER}/${_aefi_OldAppEnvFilename_}"

	if [[ ! -f ${_aefi_AppEnvFile_} && -f ${_aefi_OldAppEnvFile_} ]]; then
		# Migrate from the old env_files/appname.env files to .env.app.appname
		notice "Renaming '{{|File|}}${_aefi_OldAppEnvFile_}{{[-]}}' to '{{|File|}}${_aefi_AppEnvFile_}{{[-]}}'"
		RunAndLog "" "mv:notice" \
			fatal "Failed to rename file." \
			mv "${_aefi_OldAppEnvFile_}" "${_aefi_AppEnvFile_}"
		local _aefi_SearchString_="${APP_ENV_FOLDER_NAME}/${_aefi_OldAppEnvFilename_}"
		if [[ -f ${COMPOSE_OVERRIDE} ]] && ${GREP} -q -F "${_aefi_SearchString_}" "${COMPOSE_OVERRIDE}"; then
			local _aefi_ReplaceString_="${_aefi_AppEnvFilename_}"
			# Replace all references to 'env_files/appname.env' with '.env.app.appname' in the override file
			notice "Replacing in '{{|File|}}${COMPOSE_OVERRIDE}{{[-]}}':"
			notice "   '{{|Var|}}${_aefi_SearchString_}{{[-]}}' with '{{|Var|}}${_aefi_ReplaceString_}{{[-]}}'"
			# Escape . to [.] to use in sed
			_aefi_SearchString_="${_aefi_SearchString_//./[.]}"
			RunAndLog "" "sed:notice" \
				fatal "Failed to edit override file." \
				"${SED}" -i "s|${_aefi_SearchString_}|${_aefi_ReplaceString_}|g" "${COMPOSE_OVERRIDE}"
		fi
	fi
	_aefi_out_="${_aefi_AppEnvFile_}"
}

test_app_env_file_into() {
	for AppName in watchtower radarr radarr__4k; do
		local Result
		run_script 'app_env_file_into' Result "${AppName}"
		notice "[${AppName}] [${Result}]"
	done
}
