#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_instance_folder() {
	local result
	run_script 'app_instance_folder_into' result "$@"
	echo "${result}"
}

test_app_instance_folder() {
	for AppName in watchtower watchtower__number2; do
		notice "[${AppName}]"
		local InstanceFolder
		InstanceFolder="$(run_script 'app_instance_folder' "${AppName}")"
		notice "[${InstanceFolder}]"
		ls -lah "${InstanceFolder}"
	done
}
