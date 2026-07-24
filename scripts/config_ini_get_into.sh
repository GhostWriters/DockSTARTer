#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_ini_get_into() {
	# config_ini_get_into OutVar section_key [config_file]
	local -n _cigi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _cigi_section_key_=${2-}
	local _cigi_config_file_=${3:-$APPLICATION_INI_FILE}

	local _cigi_file_extension_=${_cigi_config_file_##*.}
	if [[ ${_cigi_file_extension_} != "ini" ]]; then
		return 1
	fi

	local -A _cigi_IniMap_=(
		["paths.config_folder"]="ConfigFolder"
		["paths.compose_folder"]="ComposeFolder"
		["pm.package_manager"]="PackageManager"
		["ui.theme"]="Theme"
		["ui.scrollbar"]="Scrollbar:Scrollbars"
		["ui.shadow"]="Shadow:Shadows"
	)

	local -A _cigi_Config_booleans_=(
		["ui.borders"]=1
		["ui.line_characters"]=1
		["ui.scrollbar"]=1
		["ui.shadow"]=1
	)

	local -A _cigi_Config_strings_=(
		["paths.config_folder"]=1
		["paths.compose_folder"]=1
		["pm.package_manager"]=1
		["ui.theme"]=1
	)

	local _cigi_VarType_
	if [[ -v _cigi_Config_booleans_[${_cigi_section_key_}] ]]; then
		_cigi_VarType_="bool"
	elif [[ -v _cigi_Config_strings_[${_cigi_section_key_}] ]]; then
		_cigi_VarType_="string"
	else
		return 1
	fi

	case ${_cigi_section_key_} in
		ui.borders)
			local _cigi_val_
			if get_ini_val_${_cigi_VarType_}_into _cigi_val_ "${_cigi_config_file_}" Borders; then
				_cigi_out_="${_cigi_val_}"
				return 0
			elif get_ini_val_${_cigi_VarType_}_into _cigi_val_ "${_cigi_config_file_}" LineCharacters; then
				# Old INI files used LineCharacters for the Borders property
				_cigi_out_="${_cigi_val_}"
				return 0
			fi
			;;
		ui.line_characters)
			local _cigi_val_
			if ! get_ini_val_${_cigi_VarType_}_into _cigi_val_ "${_cigi_config_file_}" Borders; then
				# Old INI files used LineCharacters for the Borders property
				return 1
			fi
			if get_ini_val_${_cigi_VarType_}_into _cigi_val_ "${_cigi_config_file_}" LineCharacters; then
				_cigi_out_="${_cigi_val_}"
				return 0
			fi
			;;
		*)
			if [[ -v _cigi_IniMap_["${_cigi_section_key_}"] ]]; then
				local _cigi_Var_ _cigi_val_
				for _cigi_Var_ in ${_cigi_IniMap_["${_cigi_section_key_}"]//:/$'\n'}; do
					if get_ini_val_${_cigi_VarType_}_into _cigi_val_ "${_cigi_config_file_}" "${_cigi_Var_}"; then
						_cigi_out_="${_cigi_val_}"
						return 0
					fi
				done
			fi
			;;
	esac
	return 1
}

test_config_ini_get_into() {
	warn "CI does not test config_ini_get_into."
}
