#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	sed
)

app_instance_file_into() {
	local -n _aifi_out_="${1}"
	assert_nameref_is_string "${1}"
	shift
	local -l _aifi_appname_=${1:-}
	local _aifi_FilenameTemplate_=${2:-}

	if [[ ! -d ${INSTANCES_FOLDER} ]]; then
		mkdir -p "${INSTANCES_FOLDER}" ||
			fatal \
				"Failed to create folder '{{|Folder|}}${INSTANCES_FOLDER}{{[-]}}'." \
				"Failing command: mkdir -p \"${INSTANCES_FOLDER}\""
		run_script 'set_permissions' "${INSTANCES_FOLDER}"
	fi

	local -l _aifi_baseapp_
	run_script 'appname_to_baseappname_into' _aifi_baseapp_ "${_aifi_appname_}"

	local _aifi_TemplateFolder_="${TEMPLATES_FOLDER}/${_aifi_baseapp_}"
	local _aifi_InstanceTemplateFolder_="${INSTANCES_FOLDER}/${TEMPLATES_FOLDER_NAME}/${_aifi_appname_}"
	local _aifi_InstanceFolder_="${INSTANCES_FOLDER}/${_aifi_appname_}"

	local _aifi_TemplateFile_="${_aifi_TemplateFolder_}/${_aifi_FilenameTemplate_//"*"/"${_aifi_baseapp_}"}"
	local _aifi_InstanceTemplateFile_="${_aifi_InstanceTemplateFolder_}/${_aifi_FilenameTemplate_//"*"/"${_aifi_appname_}"}"
	local _aifi_InstanceFile_="${_aifi_InstanceFolder_}/${_aifi_FilenameTemplate_//"*"/"${_aifi_appname_}"}"

	_aifi_out_="${_aifi_InstanceFile_}"

	if [[ ! -d ${_aifi_TemplateFolder_} ]]; then
		# Template folder doesn't exist, remove any instance folders associated with it and return
		for _aifi_Folder_ in "${_aifi_InstanceTemplateFolder_}" "${_aifi_InstanceFolder_}"; do
			if [[ -d ${_aifi_Folder_} ]]; then
				run_script 'set_permissions' "${_aifi_Folder_}"
				rm -rf "${_aifi_Folder_}" &> /dev/null ||
					error \
						"Failed to remove directory." \
						"Failing command: {{|FailingCommand|}}rm -rf \"${_aifi_Folder_}\""
			fi
		done
		return
	fi

	if [[ ! -f ${_aifi_TemplateFile_} ]]; then
		# Template file doesn't exist, remove any instance files associated with it and return
		for _aifi_File_ in "${_aifi_InstanceTemplateFile_}" "${_aifi_InstanceFile_}"; do
			if [[ -f ${_aifi_File_} ]]; then
				run_script 'set_permissions' "${_aifi_File_}"
				rm -f "${_aifi_File_}" &> /dev/null ||
					error \
						"Failed to remove file." \
						"Failing command: {{|FailingCommand|}}rm -f \"${_aifi_File_}\""
			fi
		done
		return
	fi

	if [[ -f ${_aifi_InstanceFile_} && -f ${_aifi_InstanceTemplateFile_} ]] && cmp -s "${_aifi_TemplateFile_}" "${_aifi_InstanceTemplateFile_}"; then
		# The instance file exists, and the template file has not changed, nothing to do.
		return
	fi

	# If we got here, the instance file needs to be created

	if [[ ! -d ${_aifi_InstanceFolder_} ]]; then
		# Create the folder to place the instance file in
		mkdir -p "${_aifi_InstanceFolder_}" ||
			fatal \
				"Failed to create folder '{{|Folder|}}${_aifi_InstanceFolder_}{{[-]}}'." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${_aifi_InstanceFolder_}\""
		run_script 'set_permissions' "${_aifi_InstanceFolder_}"
	fi

	# Create the instance file based on the template file
	local _aifi_instance_
	run_script 'appname_to_instancename_into' _aifi_instance_ "${_aifi_appname_}"
	local _aifi_INSTANCE_ _aifi_Instance_ _aifi_instance_lc_
	if [[ -n ${_aifi_instance_} ]]; then
		_aifi_INSTANCE_="__${_aifi_instance_^^}"
		local _aifi_cap_prefix_ _aifi_cap_rest_
		_aifi_cap_prefix_="${_aifi_instance_%%[a-zA-Z]*}"
		_aifi_cap_rest_="${_aifi_instance_#"${_aifi_cap_prefix_}"}"
		_aifi_Instance_="__${_aifi_cap_prefix_}${_aifi_cap_rest_^}"
		_aifi_instance_lc_="__${_aifi_instance_,,}"
	fi
	${SED} -e "s/<__INSTANCE>/${_aifi_INSTANCE_-}/g ; s/<__instance>/${_aifi_instance_lc_-}/g ; s/<__Instance>/${_aifi_Instance_-}/g" \
		"${_aifi_TemplateFile_}" > "${_aifi_InstanceFile_}"
	run_script 'set_permissions' "${_aifi_InstanceFile_}"

	if [[ ! -d ${_aifi_InstanceTemplateFolder_} ]]; then
		# Create the folder to place the copy of the template file in
		mkdir -p "${_aifi_InstanceTemplateFolder_}" ||
			fatal \
				"Failed to create folder '{{|Folder|}}${_aifi_InstanceTemplateFolder_}{{[-]}}'." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${_aifi_InstanceTemplateFolder_}\""
		run_script 'set_permissions' "${_aifi_InstanceTemplateFolder_}"
	fi

	# Copy the original template file
	cp "${_aifi_TemplateFile_}" "${_aifi_InstanceTemplateFile_}" ||
		fatal \
			"Failed to copy file." \
			"Failing command: {{|FailingCommand|}}cp \"${_aifi_TemplateFile_}\" \"${_aifi_InstanceTemplateFile_}\""
	run_script 'set_permissions' "${_aifi_InstanceTemplateFile_}"
}

test_app_instance_file_into() {
	for AppName in watchtower watchtower__number2; do
		for Template in "*.labels.yml" ".env"; do
			notice "[${AppName}] [${Template}]"
			local InstanceFile
			run_script 'app_instance_file_into' InstanceFile "${AppName}" "${Template}"
			notice "[${InstanceFile}]"
			cat "${InstanceFile}"
		done
	done
}
