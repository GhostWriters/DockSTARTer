#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	jq
)

config_json_get_into() {
	# config_json_get_into OutVar JqPath ConfigFile
	# Reads a value from a JSON file at the given jq path (e.g. ".APIKey" or ".rpc.host-whitelist").
	local -n _cjgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _cjgi_path_=${2-}
	local _cjgi_config_file_=${3-}

	_cjgi_out_=""

	if [[ -z ${_cjgi_path_} || -z ${_cjgi_config_file_} ]]; then
		return 1
	fi
	if [[ ! -f ${_cjgi_config_file_} ]]; then
		return 1
	fi

	local _cjgi_value_
	_cjgi_value_=$(jq -r "${_cjgi_path_} // empty" "${_cjgi_config_file_}" 2> /dev/null) || return 1
	if [[ -z ${_cjgi_value_} ]]; then
		return 1
	fi
	_cjgi_out_="${_cjgi_value_}"
}

test_config_json_get_into() {
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.test_config_json_get_into.XXXXXXXXXX")
	printf '{"APIKey":"abc123","nested":{"key":"value"}}\n' > "${TempFile}"

	local Result
	run_script 'config_json_get_into' Result ".APIKey" "${TempFile}"
	local -i result=0
	if [[ ${Result} != "abc123" ]]; then
		error "Expected abc123, got ${Result}"
		result=1
	fi
	run_script 'config_json_get_into' Result ".nested.key" "${TempFile}"
	if [[ ${Result} != "value" ]]; then
		error "Nested read failed: ${Result}"
		result=1
	fi
	rm -f "${TempFile}"
	return ${result}
}
