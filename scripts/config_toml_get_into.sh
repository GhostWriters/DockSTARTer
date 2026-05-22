#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_toml_get_into() {
	# config_toml_get_into OutVar section_key [config_file]
	local -n _ctgi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _ctgi_section_key_=${2-}
	local _ctgi_config_file_=${3:-$APPLICATION_TOML_FILE}

	local _ctgi_file_extension_=${_ctgi_config_file_##*.}
	if [[ ${_ctgi_file_extension_} != "toml" ]]; then
		return 1
	fi

	local -A _ctgi_Config_booleans_=(
		["ui.borders"]=1
		["ui.line_characters"]=1
		["ui.scrollbar"]=1
		["ui.shadow"]=1
	)

	local _ctgi_VarType_
	if [[ -v _ctgi_Config_booleans_[${_ctgi_section_key_}] ]]; then
		_ctgi_VarType_="bool"
	else
		_ctgi_VarType_="string"
	fi

	local _ctgi_val_
	if get_toml_val_${_ctgi_VarType_}_into _ctgi_val_ "${_ctgi_config_file_}" "${_ctgi_section_key_}"; then
		_ctgi_out_="${_ctgi_val_}"
		return 0
	fi
	return 1
}

test_config_toml_get_into() {
	warn "CI does not test config_toml_get_into."
}
