#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varname_to_appname_into() {
	local -n _vtai_out_="${1}"
	local _vtai_VarName_=${2-}
	if [[ ${_vtai_VarName_} == *":"* ]]; then
		_vtai_out_="${_vtai_VarName_%:*}"
	elif [[ ${_vtai_VarName_} =~ ^([A-Z][A-Z0-9]*(__[A-Z0-9]+)?)__[A-Za-z0-9] ]]; then
		_vtai_out_="${BASH_REMATCH[1]}"
	else
		_vtai_out_=""
	fi
}

test_varname_to_appname_into() {
	local -a Tests=(
		SONARR_CONTAINER_NAME ""
		SONARR__CONTAINER_NAME "SONARR"
		SONARR__4K__CONTAINER_NAME "SONARR__4K"
		SONARR__4K__CONTAINER_NAME__TEST "SONARR__4K"
		SONARR__4K__CONTAINER__NAME "SONARR__4K"
		SONARR_4K__CONTAINER__NAME ""
		DOCKER_VOLUME_STORAGE ""
	)
	local -i result=0
	for ((i = 0; i < ${#Tests[@]}; i += 2)); do
		local Result
		run_script 'varname_to_appname_into' Result "${Tests[i]}"
		if [[ ${Result} != "${Tests[i + 1]}" ]]; then
			error "[${Tests[i]}]: expected [${Tests[i + 1]}] got [${Result}]"
			result=1
		else
			notice "[${Tests[i]}] = [${Result}]"
		fi
	done
	return ${result}
}
