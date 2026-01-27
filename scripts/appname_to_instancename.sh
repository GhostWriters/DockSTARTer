#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_to_instancename() {
	local AppName=${1-}
	if [[ ${AppName} == *"__"* ]]; then
		echo "${AppName#*__}"
	else
		echo ""
	fi
}

test_appname_to_instancename() {
	for AppName in RADARR RADARR__4K; do
		notice "[${AppName}] [$(run_script 'appname_to_instancename' "${AppName}")]"
	done
}
