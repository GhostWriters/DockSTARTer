#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_get_into() {
	# config_get_into OutVar section_key [config_file]
	local -n _cgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _cgi_section_key_=${2-}
	local _cgi_config_file_=${3:-$APPLICATION_TOML_FILE}

	local _cgi_file_extension_=${_cgi_config_file_##*.}
	local _cgi_val_

	case ${_cgi_file_extension_} in
		toml)
			if run_script 'config_toml_get_into' _cgi_val_ "${_cgi_section_key_}" "${_cgi_config_file_}"; then
				_cgi_out_="${_cgi_val_}"
				return 0
			fi
			;;
		ini)
			if run_script 'config_ini_get_into' _cgi_val_ "${_cgi_section_key_}" "${_cgi_config_file_}"; then
				_cgi_out_="${_cgi_val_}"
				return 0
			fi
			;;
	esac

	return 1
}

test_config_get_into() {
	warn "CI does not test config_get_into."
}
