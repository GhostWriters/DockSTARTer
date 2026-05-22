#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_instance_folder() {
	local _aifld_result_
	run_script 'app_instance_folder_into' _aifld_result_ "$@"
	echo "${_aifld_result_}"
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
