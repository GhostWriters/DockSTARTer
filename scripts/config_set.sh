#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_set() {
	# config_set SET_VAR NEW_VAL [VAR_FILE]
	local section_key=${1-}
	local value=${2-}
	local config_file=${3:-$APPLICATION_TOML_FILE}

	local file_extension=${config_file##*.}

	case ${file_extension} in
		toml)
			run_script 'config_toml_set' "${section_key}" "${value}" "${config_file}"
			return
			;;
	esac

	# Invalid file extension
	return 1
}

test_config_set() {
	warn "CI does not test config_set."
}
