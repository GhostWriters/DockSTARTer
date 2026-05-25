#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	xmlstarlet
)

config_xml_get_into() {
	# config_xml_get_into OutVar XPath ConfigFile
	# Reads the text content of an XML node at the given XPath.
	# Example: config_xml_get_into Key "//Config/ApiKey" "/path/to/config.xml"
	local -n _cxgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _cxgi_xpath_=${2-}
	local _cxgi_config_file_=${3-}

	_cxgi_out_=""

	if [[ -z ${_cxgi_xpath_} || -z ${_cxgi_config_file_} ]]; then
		return 1
	fi
	if [[ ! -f ${_cxgi_config_file_} ]]; then
		return 1
	fi

	local _cxgi_value_
	_cxgi_value_=$(xmlstarlet sel -t -v "${_cxgi_xpath_}" "${_cxgi_config_file_}" 2> /dev/null) || return 1
	if [[ -z ${_cxgi_value_} ]]; then
		return 1
	fi
	_cxgi_out_="${_cxgi_value_}"
}

test_config_xml_get_into() {
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.test_config_xml_get_into.XXXXXXXXXX")
	printf '<?xml version="1.0"?>\n<Config><ApiKey>deadbeef</ApiKey></Config>\n' > "${TempFile}"

	local Result
	run_script 'config_xml_get_into' Result "//Config/ApiKey" "${TempFile}"
	local -i result=0
	if [[ ${Result} != "deadbeef" ]]; then
		error "Expected deadbeef, got ${Result}"
		result=1
	fi
	rm -f "${TempFile}"
	return ${result}
}
