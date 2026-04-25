#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_get() {
	# config_get section_key [config_file]
	local section_key=${1-}
	local config_file=${2:-$APPLICATION_TOML_FILE}

	local file_extension=${config_file##*.}

	case ${file_extension} in
		toml)
			run_script 'config_toml_get' "${section_key}" "${config_file}"
			return
			;;
		ini)
			run_script 'config_ini_get' "${section_key}" "${config_file}"
			return
			;;
	esac

	# Invalid file extension
	return 1
}

test_config_get() {
	warn "CI does not test config_get."
}
