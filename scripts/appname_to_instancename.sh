#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_to_instancename() {
	local _atin_result_
	run_script 'appname_to_instancename_into' _atin_result_ "$@"
	echo "${_atin_result_}"
}

test_appname_to_instancename() {
	for AppName in RADARR RADARR__4K; do
		notice "[${AppName}] [$(run_script 'appname_to_instancename' "${AppName}")]"
	done
}
