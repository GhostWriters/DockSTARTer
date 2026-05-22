#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_to_baseappname() {
	local result
	run_script 'appname_to_baseappname_into' result "$@"
	echo "${result}"
}

test_appname_to_baseappname() {
	for AppName in RADARR RADARR__4K; do
		notice "[${AppName}] [$(run_script 'appname_to_baseappname' "${AppName}")]"
	done
}
