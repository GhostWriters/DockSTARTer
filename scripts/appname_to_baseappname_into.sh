#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

appname_to_baseappname_into() {
	local -n _atbn_out_="${1}"
	local _atbn_AppName_=${2-}
	_atbn_out_="${_atbn_AppName_%__*}"
}

test_appname_to_baseappname_into() {
	for AppName in RADARR RADARR__4K; do
		local Result
		run_script 'appname_to_baseappname_into' Result "${AppName}"
		notice "[${AppName}] [${Result}]"
	done
}
