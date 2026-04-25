#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_toml_get() {
	# config_toml_get [SECTION_KEY] [CONFIG_FILE]
	local section_key=${1-}
	local config_file=${2:-$APPLICATION_TOML_FILE}

	local file_extension=${config_file##*.}
	if [[ ${file_extension} != "toml" ]]; then
		return 1
	fi

	local -A Config_booleans=(
		["ui.borders"]=1
		["ui.line_characters"]=1
		["ui.scrollbar"]=1
		["ui.shadow"]=1
	)

	local -A Config_strings=(
		["paths.config_folder"]=1
		["paths.compose_folder"]=1
		["pm.package_manager"]=1
		["ui.theme"]=1
	)

	local VarType
	if [[ -v Config_booleans[${section_key}] ]]; then
		VarType="bool"
	elif [[ -v Config_strings[${section_key}] ]]; then
		VarType="string"
	else
		VarType="string"
	fi

	get_toml_val_${VarType} "${config_file}" "${section_key}"
}

test_config_toml_get() {
	warn "CI does not test config_toml_get."
}
