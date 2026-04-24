#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {

	# Early return if the TOML config already exists
	if [[ -f ${APPLICATION_TOML_FILE} ]]; then
		return 0
	fi

	if [[ ! -d ${APPLICATION_CONFIG_FOLDER} ]]; then
		notice "Creating '{{|Folder|}}${APPLICATION_CONFIG_FOLDER}{{[-]}}'."
		mkdir -p "${APPLICATION_CONFIG_FOLDER}" ||
			fatal \
				"Failed to create config folder." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${APPLICATION_CONFIG_FOLDER}\""
		run_script 'set_permissions' "${APPLICATION_CONFIG_FOLDER}"
	fi

	local ComposeFolderFound=false
	# Handle legacy config files
	if [[ -f ${SCRIPTPATH}/${APPLICATION_INI_NAME} || -f ${SCRIPTPATH}/menu.ini || -f ${XDG_CONFIG_HOME}/${APPLICATION_INI_NAME} ]]; then
		for LegacyIniFile in "${XDG_CONFIG_HOME}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/menu.ini"; do
			if [[ -f ${LegacyIniFile} ]]; then
				if [[ ${LegacyIniFile} == "${APPLICATION_INI_FILE}" ]]; then
					continue
				fi
				notice "Renaming '{{|File|}}${LegacyIniFile}{{[-]}}' to '{{|File|}}${APPLICATION_INI_FILE}{{[-]}}'."
				mv "${LegacyIniFile}" "${APPLICATION_INI_FILE}" ||
					fatal \
						"Failed to rename old config file." \
						"Failing command: {{|FailingCommand|}}mv \"${LegacyIniFile}\" \"${APPLICATION_INI_FILE}\""
				break
			fi
		done
		run_script 'set_permissions' "${APPLICATION_INI_FILE}"
	fi

	if [[ -f ${APPLICATION_INI_FILE} ]]; then
		# Migrate from INI to TOML
		notice "Migrating '{{|File|}}${APPLICATION_INI_FILE}{{[-]}}' to '{{|File|}}${APPLICATION_TOML_FILE}{{[-]}}'."

		cp "${DEFAULT_TOML_FILE}" "${APPLICATION_TOML_FILE}" ||
			fatal \
				"Failed to copy default config file." \
				"Failing command: {{|FailingCommand|}}cp \"${DEFAULT_TOML_FILE}\" \"${APPLICATION_TOML_FILE}\""
		run_script 'set_permissions' "${APPLICATION_TOML_FILE}"

		local -A TOMLtoINIMap_strings=(
			["paths.config_folder"]="ConfigFolder"
			["ui.theme"]="Theme"
			["pm.package_manager"]="PackageManager"
		)

		local -A TOMLtoINIMap_booleans=(
			["ui.scrollbar"]="Scrollbar:Scrollbars"
			["ui.shadow"]="Shadow:Shadows"
		)

		if run_script 'env_var_exists' ComposeFolder "${APPLICATION_INI_FILE}"; then
			set_toml_val_string \
				"${APPLICATION_TOML_FILE}" \
				paths.compose_folder \
				"$(run_script 'config_get' ComposeFolder "${APPLICATION_INI_FILE}")"
			ComposeFolderFound=true
		fi

		for Key in "${!TOMLtoINIMap_strings[@]}"; do
			if run_script 'env_var_exists' "${TOMLtoINIMap_strings["${Key}"]}" "${APPLICATION_INI_FILE}"; then
				set_toml_val_string \
					"${APPLICATION_TOML_FILE}" \
					"${Key}" \
					"$(run_script 'config_get' "${TOMLtoINIMap_strings["${Key}"]}" "${APPLICATION_INI_FILE}")"
			fi
		done

		# Migrate LineCharacters to ui.borders if Borders doesn't exist (old INI settings)
		if run_script 'env_var_exists' Borders "${APPLICATION_INI_FILE}"; then
			set_toml_val_bool \
				"${APPLICATION_TOML_FILE}" \
				ui.borders \
				"$(run_script 'config_get' Borders "${APPLICATION_INI_FILE}")"
			if run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
				set_toml_val_bool \
					"${APPLICATION_TOML_FILE}" \
					ui.line_characters \
					"$(run_script 'config_get' LineCharacters "${APPLICATION_INI_FILE}")"
			fi
		elif run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
			set_toml_val_bool \
				"${APPLICATION_TOML_FILE}" \
				ui.borders \
				"$(run_script 'config_get' LineCharacters "${APPLICATION_INI_FILE}")"
		fi

		for Key in "${!TOMLtoINIMap_booleans[@]}"; do
			local VarList
			VarList="${TOMLtoINIMap_booleans["${Key}"]}"
			for Val in ${VarList//:/ }; do
				if run_script 'env_var_exists' "${Val}" "${APPLICATION_INI_FILE}"; then
					set_toml_val_bool \
						"${APPLICATION_TOML_FILE}" \
						"${Key}" \
						"$(run_script 'config_get' "${Val}" "${APPLICATION_INI_FILE}")"
					break
				fi
			done
		done
	else
		# Fresh install: copy the default TOML file
		notice "Copying '{{|File|}}${DEFAULT_TOML_FILE}{{[-]}}' to '{{|File|}}${APPLICATION_TOML_FILE}{{[-]}}'."
		cp "${DEFAULT_TOML_FILE}" "${APPLICATION_TOML_FILE}" ||
			fatal \
				"Failed to copy default config file." \
				"Failing command: {{|FailingCommand|}}cp \"${DEFAULT_TOML_FILE}\" \"${APPLICATION_TOML_FILE}\""
		run_script 'set_permissions' "${APPLICATION_TOML_FILE}"
	fi

	if [[ ${ComposeFolderFound} == false ]]; then
		detect_compose_folder
	fi

	notice ""
	notice "$(run_script 'config_show')"
	notice ""
}

detect_compose_folder() {
	# Check for a legacy compose folder and update ComposeFolder if needed
	local ConfigFolder
	ConfigFolder="$(get_toml_val_string "${APPLICATION_TOML_FILE}" paths.config_folder)"

	local -a ExpandVarList=(
		ScriptFolder "${SCRIPTPATH}"
		XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
		HOME "${DETECTED_HOMEDIR}"
	)
	local ExpandedConfigFolder
	ExpandedConfigFolder="$(expand_vars "${ConfigFolder}" "${ExpandVarList[@]}")"
	ExpandVarList=(
		DOCKER_CONFIG_FOLDER "${ExpandedConfigFolder}"
		"${ExpandVarList[@]}"
	)

	# shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
	local LegacyComposeFolder='${ScriptFolder}/compose'
	local ExpandedLegacyComposeFolder
	ExpandedLegacyComposeFolder="$(expand_vars "${LegacyComposeFolder}" "${ExpandVarList[@]}")"

	local LegacyHasFiles=false
	if [[ -d ${ExpandedLegacyComposeFolder} ]] && ! folder_is_empty "${ExpandedLegacyComposeFolder}"; then
		LegacyHasFiles=true
	fi

	local DefaultComposeFolder
	DefaultComposeFolder="$(get_toml_val_string "${APPLICATION_TOML_FILE}" paths.compose_folder)"
	local ExpandedDefaultComposeFolder
	ExpandedDefaultComposeFolder="$(expand_vars "${DefaultComposeFolder}" "${ExpandVarList[@]}")"

	local DefaultHasFiles=false
	if [[ -d ${ExpandedDefaultComposeFolder} ]] && ! folder_is_empty "${ExpandedDefaultComposeFolder}"; then
		DefaultHasFiles=true
	fi

	if [[ ${LegacyHasFiles} == true ]] && [[ ${DefaultHasFiles} == true ]] && [[ ${ExpandedLegacyComposeFolder} != "${ExpandedDefaultComposeFolder}" ]]; then
		local PromptMessage="Existing docker compose folders found in multiple locations.\n   Legacy:  '{{|Folder|}}${ExpandedLegacyComposeFolder}{{[-]}}'\n   Default: '{{|Folder|}}${ExpandedDefaultComposeFolder}{{[-]}}'\n\nWould you like to use the Legacy location?"
		if run_script 'question_prompt' "Y" "${PromptMessage}" "Multiple Compose Folders Detected" "" "Legacy" "Default"; then
			notice \
				"Chose the Legacy compose folder location:" \
				"   '{{|Folder|}}${ExpandedLegacyComposeFolder}{{[-]}}'"
			set_toml_val_string "${APPLICATION_TOML_FILE}" paths.compose_folder "${LegacyComposeFolder}"
		else
			notice \
				"Chose the Default compose folder location:" \
				"   '{{|Folder|}}${ExpandedDefaultComposeFolder}{{[-]}}'"
		fi
	elif [[ ${LegacyHasFiles} == true ]]; then
		set_toml_val_string "${APPLICATION_TOML_FILE}" paths.compose_folder "${LegacyComposeFolder}"
	fi
}

test_config_create() {
	warn "CI does not test create_config."
}
