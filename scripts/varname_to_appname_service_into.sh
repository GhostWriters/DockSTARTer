#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Returns the DS application name based on the variable name passed,
# preserving any service/shared qualifier (e.g. "IMMICH___ML" for
# "IMMICH___ML__CONTAINER_NAME"). Mirrors varname_to_appname.sh: if the name
# contains ":", the part before the colon is the app name; otherwise the
# app name is extracted via the double-underscore pattern, tried against
# the triple-underscore "service" form first -- the plain two-segment
# pattern would otherwise partially match and silently swallow the service
# marker. Most callers want the bare app name instead -- see
# varname_to_appname_into.
varname_to_appname_service_into() {
	local -n _vtasi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _vtasi_VarName_=${2-}
	if [[ ${_vtasi_VarName_} == *":"* ]]; then
		_vtasi_out_="${_vtasi_VarName_%:*}"
	elif [[ ${_vtasi_VarName_} =~ ^([A-Z][A-Z0-9]*)(__[A-Z0-9]+)?___([A-Z0-9]+)__[A-Za-z0-9] ]]; then
		_vtasi_out_="${BASH_REMATCH[1]}${BASH_REMATCH[2]}___${BASH_REMATCH[3]}"
	elif [[ ${_vtasi_VarName_} =~ ^([A-Z][A-Z0-9]*(__[A-Z0-9]+)?)__[A-Za-z0-9] ]]; then
		_vtasi_out_="${BASH_REMATCH[1]}"
	else
		_vtasi_out_=""
	fi
}

test_varname_to_appname_service_into() {
	local -a Tests=(
		SONARR_CONTAINER_NAME ""
		SONARR__CONTAINER_NAME "SONARR"
		SONARR__4K__CONTAINER_NAME "SONARR__4K"
		SONARR__4K__CONTAINER_NAME__TEST "SONARR__4K"
		SONARR__4K__CONTAINER__NAME "SONARR__4K"
		SONARR_4K__CONTAINER__NAME ""
		DOCKER_VOLUME_STORAGE ""
		# Multi-service scheme: full identity including the service segment,
		# not silently dropped.
		IMMICH___POSTGRES__CONTAINER_NAME "IMMICH___POSTGRES"
		IMMICH__MYINSTANCE___POSTGRES__CONTAINER_NAME "IMMICH__MYINSTANCE___POSTGRES"
		IMMICH__MYINSTANCE__CONTAINER_NAME "IMMICH__MYINSTANCE"
	)
	local -i result=0
	for ((i = 0; i < ${#Tests[@]}; i += 2)); do
		local Result
		run_script 'varname_to_appname_service_into' Result "${Tests[i]}"
		if [[ ${Result} != "${Tests[i + 1]}" ]]; then
			error "[${Tests[i]}]: expected [${Tests[i + 1]}] got [${Result}]"
			result=1
		else
			notice "[${Tests[i]}] = [${Result}]"
		fi
	done
	return ${result}
}
