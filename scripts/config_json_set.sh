#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	jq
)

config_json_set() {
	# config_json_set JqPath Value ConfigFile
	# Writes a value to a JSON file at the given jq path.
	# Value is treated as a string; for non-string types pass a JSON literal
	# wrapped in single quotes, e.g. 'true' or '[1,2,3]' and use raw-json mode
	# by prefixing the path with `=raw:` (handled below).
	local path=${1-}
	local value=${2-}
	local config_file=${3-}

	if [[ -z ${path} || -z ${config_file} ]]; then
		error "config_json_set requires PATH and CONFIG_FILE."
		return 1
	fi

	if [[ ! -f ${config_file} ]]; then
		printf '{}\n' > "${config_file}"
	fi

	local raw_mode="false"
	if [[ ${path} == "=raw:"* ]]; then
		raw_mode="true"
		path="${path#=raw:}"
	fi

	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.config_json_set.XXXXXXXXXX")

	if [[ ${raw_mode} == "true" ]]; then
		jq "${path} = ${value}" "${config_file}" > "${TempFile}" || {
			rm -f "${TempFile}"
			error "jq raw write failed for ${path} in ${config_file}"
			return 1
		}
	else
		jq --arg v "${value}" "${path} = \$v" "${config_file}" > "${TempFile}" || {
			rm -f "${TempFile}"
			error "jq string write failed for ${path} in ${config_file}"
			return 1
		}
	fi

	if [[ -s ${TempFile} ]]; then
		mv "${TempFile}" "${config_file}"
	else
		rm -f "${TempFile}"
		error "jq produced empty output; refusing to overwrite ${config_file}"
		return 1
	fi
}

test_config_json_set() {
	local TempFile
	TempFile=$(mktemp -t "${APPLICATION_NAME}.test_config_json_set.XXXXXXXXXX")
	printf '{"existing":"old"}\n' > "${TempFile}"

	run_script 'config_json_set' ".existing" "new" "${TempFile}"
	run_script 'config_json_set' ".fresh" "added" "${TempFile}"
	run_script 'config_json_set' "=raw:.flag" "true" "${TempFile}"

	local -i result=0
	if ! jq -e '.existing == "new"' "${TempFile}" > /dev/null; then
		error "Existing key not updated."
		result=1
	fi
	if ! jq -e '.fresh == "added"' "${TempFile}" > /dev/null; then
		error "New key not added."
		result=1
	fi
	if ! jq -e '.flag == true' "${TempFile}" > /dev/null; then
		error "Raw bool not written correctly."
		result=1
	fi
	rm -f "${TempFile}"
	return ${result}
}
