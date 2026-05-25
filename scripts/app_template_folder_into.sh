#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_template_folder_into() {
	# app_template_folder_into OutVar AppName
	# Returns the template folder for an app, preferring the in-tree
	# local override at ${SCRIPTPATH}/assets/local_apps/<baseapp>/ if it
	# exists; otherwise falls back to the cloned templates repo at
	# ${TEMPLATES_FOLDER}/<baseapp>/. Used by app_is_builtin and
	# app_instance_file_into so apps shipped directly in this repo
	# (currently only nginxproxymanager) participate in the same
	# discovery path as upstream templates.
	local -n _atfi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _atfi_appname_=${2-}

	_atfi_out_=""

	if [[ -z ${_atfi_appname_} ]]; then
		return 1
	fi

	local -l _atfi_baseapp_
	run_script 'appname_to_baseappname_into' _atfi_baseapp_ "${_atfi_appname_}"

	if [[ -z ${_atfi_baseapp_} ]]; then
		return 1
	fi

	local _atfi_local_="${SCRIPTPATH}/assets/local_apps/${_atfi_baseapp_}"
	if [[ -d ${_atfi_local_} ]]; then
		_atfi_out_="${_atfi_local_}"
		return 0
	fi

	_atfi_out_="${TEMPLATES_FOLDER}/${_atfi_baseapp_}"
}

test_app_template_folder_into() {
	local Folder
	run_script 'app_template_folder_into' Folder "WATCHTOWER"
	if [[ ${Folder} != "${TEMPLATES_FOLDER}/watchtower" ]]; then
		error "Expected upstream watchtower folder, got: ${Folder}"
		return 1
	fi
}
