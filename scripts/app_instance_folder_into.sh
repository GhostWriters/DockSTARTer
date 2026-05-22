#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

app_instance_folder_into() {
	# app_instance_folder_into OutVar AppName
	# Returns the folder name of a folder in the instance folder for the app specified
	#
	# app_instance_folder_into Result "radarr" will set Result to a string similar to "/home/user/.dockstarter/instances/radarr"
	# If the folder does not exist, it is created from the matching folder in the "templates" folder.
	local -n _aifld_out_="${1}"
	local _aifld_AppName_=${2:-}
	local -l _aifld_appname_=${_aifld_AppName_}

	local _aifld_baseapp_ _aifld_TemplateFolder_ _aifld_InstanceFolder_
	run_script 'appname_to_baseappname_into' _aifld_baseapp_ "${_aifld_appname_}"
	_aifld_TemplateFolder_="${TEMPLATES_FOLDER}/${_aifld_baseapp_}"
	_aifld_InstanceFolder_="${INSTANCES_FOLDER}/${_aifld_appname_}"

	_aifld_out_="${_aifld_InstanceFolder_}"
	if [[ ! -d ${_aifld_InstanceFolder_} ]]; then
		if [[ ! -d ${_aifld_TemplateFolder_} ]]; then
			warn "Folder '{{|Folder|}}${_aifld_TemplateFolder_}{{[-]}}' does not exist."
			return
		fi
		if [[ ! -d ${_aifld_InstanceFolder_} ]]; then
			mkdir -p "${_aifld_InstanceFolder_}" ||
				fatal \
					"Failed to create folder '{{|Folder|}}${_aifld_InstanceFolder_}{{[-]}}'." \
					"Failing command: {{|FailingCommand|}}mkdir -p \"${_aifld_InstanceFolder_}\""
			run_script 'set_permissions' "${_aifld_InstanceFolder_}"
		fi
	fi
}

test_app_instance_folder_into() {
	for AppName in watchtower watchtower__number2; do
		notice "[${AppName}]"
		local Result
		run_script 'app_instance_folder_into' Result "${AppName}"
		notice "[${Result}]"
		ls -lah "${Result}"
	done
}
