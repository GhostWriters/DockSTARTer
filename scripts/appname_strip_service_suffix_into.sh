#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Strips a service/shared-file qualifier off an app name -- a real
# per-service file marker ("___service", e.g. "immich___postgres") or a
# shared/virtual grouping-file marker ("-suffix", e.g. "immich-database").
# Neither marker can appear in a real base app name ([A-Za-z0-9_] only), so
# stripping from the first occurrence of either is unambiguous. The two
# forms are never combined in one name. Mirrors DockSTARTer2's
# stripServiceSuffix (internal/appenv/naming.go).
appname_strip_service_suffix_into() {
	local -n _assi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _assi_AppName_=${2-}
	if [[ ${_assi_AppName_} == *"___"* ]]; then
		_assi_out_="${_assi_AppName_%%___*}"
	elif [[ ${_assi_AppName_} == *"-"* ]]; then
		_assi_out_="${_assi_AppName_%%-*}"
	else
		_assi_out_="${_assi_AppName_}"
	fi
}

test_appname_strip_service_suffix_into() {
	local -a Tests=(
		SONARR "SONARR"
		SONARR__4K "SONARR__4K"
		immich___postgres "immich"
		immich-database "immich"
		IMMICH__MYINSTANCE___POSTGRES "IMMICH__MYINSTANCE"
	)
	local -i result=0
	for ((i = 0; i < ${#Tests[@]}; i += 2)); do
		local Result
		run_script 'appname_strip_service_suffix_into' Result "${Tests[i]}"
		if [[ ${Result} != "${Tests[i + 1]}" ]]; then
			error "[${Tests[i]}]: expected [${Tests[i + 1]}] got [${Result}]"
			result=1
		else
			notice "[${Tests[i]}] = [${Result}]"
		fi
	done
	return ${result}
}
