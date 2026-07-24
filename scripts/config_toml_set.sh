#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_toml_set() {
	# config_toml_set SECTION_KEY VALUE [CONFIG_FILE]
	local section_key=${1-}
	local value=${2-}
	local config_file=${3:-$APPLICATION_TOML_FILE}

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
		# Variable not found, assume string
		VarType="string"
	fi

	set_toml_val_${VarType} "${config_file}" "${section_key}" "${value}"
}

test_config_toml_set() {
	warn "CI does not test config_toml_set."
}
