#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_ini_get() {
	# config_ini_get [SECTION_KEY] [CONFIG_FILE]
	local section_key=${1-}
	local config_file=${2:-$APPLICATION_INI_FILE}

	local file_extension=${config_file##*.}
	if [[ ${file_extension} != "ini" ]]; then
		return 1
	fi

	local -A IniMap=(
		["paths.config_folder"]="ConfigFolder"
		["paths.compose_folder"]="ComposeFolder"
		["pm.package_manager"]="PackageManager"
		["ui.theme"]="Theme"
		["ui.scrollbar"]="Scrollbar:Scrollbars"
		["ui.shadow"]="Shadow:Shadows"
	)

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
		# Boolean variable
		VarType="bool"
	elif [[ -v Config_strings[${section_key}] ]]; then
		# String variable
		VarType="string"
	else
		# Variable not found
		return 1
	fi

	case ${section_key} in
		ui.borders)
			local Value
			if Value=$(get_ini_val_${VarType} "${config_file}" Borders); then
				printf "%s\n" "${Value}"
				return 0
			elif Value=$(get_ini_val_${VarType} "${config_file}" LineCharacters); then
				# Old INI files used LineCharacters for the Borders property
				printf "%s\n" "${Value}"
				return 0
			fi
			;;
		ui.line_characters)
			local Value
			if ! get_ini_val_${VarType} "${config_file}" Borders > /dev/null; then
				# Old INI files used LineCharacters for the Borders property
				return 1
			fi
			if Value=$(get_ini_val_${VarType} "${config_file}" LineCharacters); then
				printf "%s\n" "${Value}"
				return 0
			fi
			;;
		*)
			if [[ -v IniMap["${section_key}"] ]]; then
				for Var in ${IniMap["${section_key}"]//:/$'\n'}; do
					local Value
					if ! Value=$(get_ini_val_${VarType} "${config_file}" "${Var}"); then
						continue
					fi
					printf "%s\n" "${Value}"
					return 0
				done
			fi
			;;
	esac
	return 1
}

test_config_ini_get() {
	warn "CI does not test config_ini_get."
}
