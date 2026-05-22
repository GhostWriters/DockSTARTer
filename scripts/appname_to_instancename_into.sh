#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

appname_to_instancename_into() {
	local -n _atin_out_="${1}"
	assert_nameref_is_string "${1}"
	local _atin_AppName_=${2-}
	if [[ ${_atin_AppName_} == *"__"* ]]; then
		_atin_out_="${_atin_AppName_#*__}"
	else
		_atin_out_=""
	fi
}

test_appname_to_instancename_into() {
	for AppName in RADARR RADARR__4K; do
		local Result
		run_script 'appname_to_instancename_into' Result "${AppName}"
		notice "[${AppName}] [${Result}]"
	done
}
