#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

var_default_value_into() {
	local -n _vdvi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _vdvi_VarName_=${2-}
	local _vdvi_CleanVarName_="${_vdvi_VarName_}"

	local _vdvi_Default_
	local _vdvi_VarType_
	local _vdvi_APPNAME_ _vdvi_appname_ _vdvi_AppName_
	run_script 'varname_to_appname_into' _vdvi_APPNAME_ "${_vdvi_VarName_}"
	if [[ -n ${_vdvi_APPNAME_} ]]; then
		_vdvi_APPNAME_="${_vdvi_APPNAME_^^}"
		_vdvi_appname_="${_vdvi_APPNAME_,,}"
		run_script 'app_nicename_into' _vdvi_AppName_ "${_vdvi_APPNAME_}"
		if [[ ${_vdvi_VarName_} == *":"* ]]; then
			_vdvi_VarType_="APPENV"
			_vdvi_CleanVarName_=${_vdvi_VarName_#*:}
			_vdvi_VarName_="${_vdvi_APPNAME_}:${_vdvi_CleanVarName_}"
		else
			_vdvi_VarType_="APP"
		fi
	else
		_vdvi_VarType_="GLOBAL"
	fi

	case "${_vdvi_VarType_}" in
		APP)
			local _vdvi_DefaultAppVarFile_
			run_script 'app_instance_file_into' _vdvi_DefaultAppVarFile_ "${_vdvi_APPNAME_}" ".env"
			if [[ -f ${_vdvi_DefaultAppVarFile_} ]] && run_script 'env_var_exists' "${_vdvi_CleanVarName_}" "${_vdvi_DefaultAppVarFile_}"; then
				run_script 'env_get_literal_into' _vdvi_out_ "${_vdvi_CleanVarName_}" "${_vdvi_DefaultAppVarFile_}"
				return
			fi
			case "${_vdvi_CleanVarName_}" in
				"${_vdvi_APPNAME_}__CONTAINER_NAME")
					_vdvi_Default_="'${_vdvi_appname_}'"
					;;
				"${_vdvi_APPNAME_}__ENABLED")
					_vdvi_Default_="'false'"
					;;
				"${_vdvi_APPNAME_}__HOSTNAME")
					_vdvi_Default_="'${_vdvi_AppName_}'"
					;;
				"${_vdvi_APPNAME_}__NETWORK_MODE")
					_vdvi_Default_="''"
					;;
				"${_vdvi_APPNAME_}__RESTART")
					_vdvi_Default_="'unless-stopped'"
					;;
				"${_vdvi_APPNAME_}__TAG")
					_vdvi_Default_="'latest'"
					;;
				"${_vdvi_APPNAME_}__VOLUME_DOCKER_SOCKET")
					# shellcheck disable=SC2016  # Expressions don't expand in single quotes, use double quotes for that.
					_vdvi_Default_='"${DOCKER_VOLUME_DOCKER_SOCKET?}"'
					;;
				*)
					if [[ ${_vdvi_CleanVarName_} =~ ^${_vdvi_APPNAME_}__PORT_[0-9]+$ ]]; then
						_vdvi_Default_="'${_vdvi_CleanVarName_#"${_vdvi_APPNAME_}"__PORT_*}'"
					else
						_vdvi_Default_="''"
					fi
					;;
			esac
			;;
		APPENV)
			local _vdvi_DefaultAppVarFile_
			run_script 'app_instance_file_into' _vdvi_DefaultAppVarFile_ "${_vdvi_APPNAME_}" ".env.app.*"
			if [[ -f ${_vdvi_DefaultAppVarFile_} ]] && run_script 'env_var_exists' "${_vdvi_CleanVarName_}" "${_vdvi_DefaultAppVarFile_}"; then
				run_script 'env_get_literal_into' _vdvi_out_ "${_vdvi_CleanVarName_}" "${_vdvi_DefaultAppVarFile_}"
				return
			fi
			_vdvi_Default_="''"
			;;
		GLOBAL)
			case "${_vdvi_CleanVarName_}" in
				DOCKER_COMPOSE_FOLDER)
					_vdvi_Default_="${LITERAL_COMPOSE_FOLDER}"
					;;
				DOCKER_CONFIG_FOLDER)
					_vdvi_Default_="${LITERAL_CONFIG_FOLDER}"
					;;
				DOCKER_GID)
					_vdvi_Default_="'$(group_id docker)'"
					;;
				DOCKER_HOSTNAME)
					_vdvi_Default_="'${HOSTNAME}'"
					;;
				GLOBAL_LAN_NETWORK)
					_vdvi_Default_="'$(run_script 'detect_lan_network')'"
					;;
				PGID)
					_vdvi_Default_="'${DETECTED_PGID}'"
					;;
				PUID)
					_vdvi_Default_="'${DETECTED_PUID}'"
					;;
				TZ)
					if [[ -f /etc/timezone ]]; then
						_vdvi_Default_="'$(cat /etc/timezone)'"
					else
						_vdvi_Default_="'Etc/UTC'"
					fi
					;;
				*)
					if [[ -f ${COMPOSE_ENV_DEFAULT_FILE} ]] && run_script 'env_var_exists' "${_vdvi_CleanVarName_}" "${COMPOSE_ENV_DEFAULT_FILE}"; then
						run_script 'env_get_literal_into' _vdvi_Default_ "${_vdvi_CleanVarName_}" "${COMPOSE_ENV_DEFAULT_FILE}"
					else
						_vdvi_Default_="''"
					fi
					;;
			esac
			;;
	esac
	_vdvi_out_="${_vdvi_Default_}"
}

test_var_default_value_into() {
	for VarName in NONEXISTENT_GLOBAL_VAR NONEXISTENTAPP__VARNAME NONEXISTENAAPP__PORT_80 NONEXISTENTAPP__HOSTNAME WATCHTOWER__HOSTNAME DOCKER_VOLUME_STORAGE; do
		local Result
		run_script 'var_default_value_into' Result "${VarName}"
		echo "${VarName}=${Result}"
	done
	notice "CI does not test var_default_value_into"
}
