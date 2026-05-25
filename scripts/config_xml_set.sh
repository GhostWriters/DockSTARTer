#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	xmlstarlet
)

config_xml_set() {
	# config_xml_set XPath Value ConfigFile
	# Updates the text content of an existing XML node at XPath.
	# If the node does not exist, creates it under the document root
	# (the XPath must use simple `/Root/Node` form for create to work).
	local xpath=${1-}
	local value=${2-}
	local config_file=${3-}

	if [[ -z ${xpath} || -z ${config_file} ]]; then
		error "config_xml_set requires XPATH and CONFIG_FILE."
		return 1
	fi

	if [[ ! -f ${config_file} ]]; then
		error "config_xml_set: file does not exist: ${config_file}"
		return 1
	fi

	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.config_xml_set.XXXXXXXXXX")

	if xmlstarlet sel -t -v "${xpath}" "${config_file}" &> /dev/null; then
		# Node exists, update it
		xmlstarlet ed -u "${xpath}" -v "${value}" "${config_file}" > "${TempFile}" || {
			rm -f "${TempFile}"
			error "xmlstarlet update failed for ${xpath} in ${config_file}"
			return 1
		}
	else
		# Node doesn't exist, create it under parent (strip the last path segment)
		local parent="${xpath%/*}"
		local leaf="${xpath##*/}"
		if [[ -z ${parent} || -z ${leaf} || ${parent} == "${xpath}" ]]; then
			rm -f "${TempFile}"
			error "config_xml_set: cannot create node at ${xpath} (need /Parent/Leaf form)"
			return 1
		fi
		xmlstarlet ed -s "${parent}" -t elem -n "${leaf}" -v "${value}" "${config_file}" > "${TempFile}" || {
			rm -f "${TempFile}"
			error "xmlstarlet insert failed for ${xpath} in ${config_file}"
			return 1
		}
	fi

	if [[ -s ${TempFile} ]]; then
		mv "${TempFile}" "${config_file}"
	else
		rm -f "${TempFile}"
		error "xmlstarlet produced empty output; refusing to overwrite ${config_file}"
		return 1
	fi
}

test_config_xml_set() {
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.test_config_xml_set.XXXXXXXXXX")
	printf '<?xml version="1.0"?>\n<Config><ApiKey>oldkey</ApiKey></Config>\n' > "${TempFile}"

	run_script 'config_xml_set' "//Config/ApiKey" "newkey" "${TempFile}"
	run_script 'config_xml_set' "/Config/NewLeaf" "newvalue" "${TempFile}"

	local Result result=0
	run_script 'config_xml_get_into' Result "//Config/ApiKey" "${TempFile}"
	if [[ ${Result} != "newkey" ]]; then
		error "Update failed: got ${Result}"
		result=1
	fi
	run_script 'config_xml_get_into' Result "//Config/NewLeaf" "${TempFile}"
	if [[ ${Result} != "newvalue" ]]; then
		error "Create failed: got ${Result}"
		result=1
	fi
	rm -f "${TempFile}"
	return ${result}
}
