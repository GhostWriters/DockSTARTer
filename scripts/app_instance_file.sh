#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_instance_file() {
	# app_instance_file AppName FilenameTemplate
	# Returns the filename of a file in the instance folder for the app specified
	#
	# app_instance_file "radarr" "*.labels.yml" will return a string similar to "/home/user/.dockstarter/instances/radarr/radarr.labels.yml"
	# If the file does not exist, it is created from the matching file in the "templates" folder.
	local result
	run_script 'app_instance_file_into' result "$@"
	echo "${result}"
}

test_app_instance_file() {
	for AppName in watchtower watchtower__number2; do
		for Template in "*.labels.yml" ".env"; do
			notice "[${AppName}] [${Template}]"
			local InstanceFile
			InstanceFile="$(run_script 'app_instance_file' "${AppName}" "${Template}")"
			notice "[${InstanceFile}]"
			cat "${InstanceFile}"
		done
	done
}
