#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_to_baseappname() {
	local _atbn_result_
	run_script 'appname_to_baseappname_into' _atbn_result_ "$@"
	echo "${_atbn_result_}"
}

test_appname_to_baseappname() {
	for AppName in RADARR RADARR__4K; do
		notice "[${AppName}] [$(run_script 'appname_to_baseappname' "${AppName}")]"
	done
}
