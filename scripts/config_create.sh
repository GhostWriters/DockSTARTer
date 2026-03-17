#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_create() {

	# Early return if the TOML config already exists
	if [[ -f ${APPLICATION_TOML_FILE} ]]; then
		return 0
	fi

	if [[ ! -d ${APPLICATION_CONFIG_FOLDER} ]]; then
		notice "Creating '${C["Folder"]-}${APPLICATION_CONFIG_FOLDER}${NC-}'."
		mkdir -p "${APPLICATION_CONFIG_FOLDER}" ||
			fatal \
				"Failed to create config folder." \
				"Failing command: ${C["FailingCommand"]}mkdir -p \"${APPLICATION_CONFIG_FOLDER}\""
		run_script 'set_permissions' "${APPLICATION_CONFIG_FOLDER}"
	fi

	# Handle legacy config files
	if [[ -f ${SCRIPTPATH}/${APPLICATION_INI_NAME} || -f ${SCRIPTPATH}/menu.ini || -f ${XDG_CONFIG_HOME}/${APPLICATION_INI_NAME} ]]; then
		for LegacyIniFile in "${XDG_CONFIG_HOME}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/${APPLICATION_INI_NAME}" "${SCRIPTPATH}/menu.ini"; do
			if [[ -f ${LegacyIniFile} ]]; then
				if [[ ${LegacyIniFile} == "${APPLICATION_INI_FILE}" ]]; then
					continue
				fi
				notice "Renaming '${C["File"]-}${LegacyIniFile}${NC-}' to '${C["File"]-}${APPLICATION_INI_FILE}${NC-}'."
				mv "${LegacyIniFile}" "${APPLICATION_INI_FILE}" ||
					fatal \
						"Failed to rename old config file." \
						"Failing command: ${C["FailingCommand"]}mv \"${LegacyIniFile}\" \"${APPLICATION_INI_FILE}\""
				break
			fi
		done
		run_script 'set_permissions' "${APPLICATION_INI_FILE}"
	fi

	local ConfigFolder ComposeFolder Theme Borders LineCharacters Scrollbar Shadow PackageManager

	if [[ -f ${APPLICATION_INI_FILE} ]]; then
		# Migrate from INI to TOML

		ConfigFolder="$(run_script 'config_get' ConfigFolder)"
		[[ -z ${ConfigFolder-} ]] && ConfigFolder="$(run_script 'config_get' ConfigFolder "${DEFAULT_INI_FILE}")"

		ComposeFolder="$(run_script 'config_get' ComposeFolder)"
		[[ -z ${ComposeFolder-} ]] && ComposeFolder="$(run_script 'config_get' ComposeFolder "${DEFAULT_INI_FILE}")"

		Theme="$(run_script 'config_get' Theme)"
		[[ -z ${Theme-} ]] && Theme="$(run_script 'config_get' Theme "${DEFAULT_INI_FILE}")"

		# Handle old installs where LineCharacters was used in place of Borders
		if run_script 'env_var_exists' Borders "${APPLICATION_INI_FILE}"; then
			Borders="$(run_script 'config_get' Borders)"
		elif run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
			Borders="$(run_script 'config_get' LineCharacters)"
		else
			Borders="$(run_script 'config_get' Borders "${DEFAULT_INI_FILE}")"
		fi
		is_true "${Borders}" && Borders="true" || Borders="false"

		if run_script 'env_var_exists' LineCharacters "${APPLICATION_INI_FILE}"; then
			LineCharacters="$(run_script 'config_get' LineCharacters)"
		else
			LineCharacters="$(run_script 'config_get' LineCharacters "${DEFAULT_INI_FILE}")"
		fi
		is_true "${LineCharacters}" && LineCharacters="true" || LineCharacters="false"

		Scrollbar="$(run_script 'config_get' Scrollbar)"
		[[ -z ${Scrollbar-} ]] && Scrollbar="$(run_script 'config_get' Scrollbar "${DEFAULT_INI_FILE}")"
		is_true "${Scrollbar}" && Scrollbar="true" || Scrollbar="false"

		Shadow="$(run_script 'config_get' Shadow)"
		[[ -z ${Shadow-} ]] && Shadow="$(run_script 'config_get' Shadow "${DEFAULT_INI_FILE}")"
		is_true "${Shadow}" && Shadow="true" || Shadow="false"

		PackageManager="$(run_script 'config_get' PackageManager)"

		notice "Migrating '${C["File"]-}${APPLICATION_INI_FILE}${NC-}' to '${C["File"]-}${APPLICATION_TOML_FILE}${NC-}'."

		set_toml_val "${APPLICATION_TOML_FILE}" "paths.config_folder" "${ConfigFolder}"
		set_toml_val "${APPLICATION_TOML_FILE}" "paths.compose_folder" "${ComposeFolder}"
		set_toml_val "${APPLICATION_TOML_FILE}" "ui.theme" "${Theme}"
		set_toml_val "${APPLICATION_TOML_FILE}" "ui.borders" "${Borders}"
		set_toml_val "${APPLICATION_TOML_FILE}" "ui.line_characters" "${LineCharacters}"
		set_toml_val "${APPLICATION_TOML_FILE}" "ui.scrollbar" "${Scrollbar}"
		set_toml_val "${APPLICATION_TOML_FILE}" "ui.shadow" "${Shadow}"
		set_toml_val "${APPLICATION_TOML_FILE}" "pm.package_manager" "${PackageManager}"

		run_script 'set_permissions' "${APPLICATION_TOML_FILE}"
	else
		# Fresh install: copy the default TOML file
		notice "Copying '${C["File"]-}${DEFAULT_TOML_FILE}${NC-}' to '${C["File"]-}${APPLICATION_TOML_FILE}${NC-}'."
		cp "${DEFAULT_TOML_FILE}" "${APPLICATION_TOML_FILE}" ||
			fatal \
				"Failed to copy default config file." \
				"Failing command: ${C["FailingCommand"]}cp \"${DEFAULT_TOML_FILE}\" \"${APPLICATION_TOML_FILE}\""
		run_script 'set_permissions' "${APPLICATION_TOML_FILE}"

		# Check for a legacy compose folder and update ComposeFolder if needed
		ConfigFolder="$(get_toml_val "${APPLICATION_TOML_FILE}" "paths.config_folder")"
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
		DefaultComposeFolder="$(get_toml_val "${APPLICATION_TOML_FILE}" "paths.compose_folder")"
		local ExpandedDefaultComposeFolder
		ExpandedDefaultComposeFolder="$(expand_vars "${DefaultComposeFolder}" "${ExpandVarList[@]}")"

		local DefaultHasFiles=false
		if [[ -d ${ExpandedDefaultComposeFolder} ]] && ! folder_is_empty "${ExpandedDefaultComposeFolder}"; then
			DefaultHasFiles=true
		fi

		if [[ ${LegacyHasFiles} == true ]] && [[ ${DefaultHasFiles} == true ]] && [[ ${ExpandedLegacyComposeFolder} != "${ExpandedDefaultComposeFolder}" ]]; then
			local PromptMessage="Existing docker compose folders found in multiple locations.\n   Legacy:  '${C["Folder"]-}${ExpandedLegacyComposeFolder}${NC-}'\n   Default: '${C["Folder"]-}${ExpandedDefaultComposeFolder}${NC-}'\n\nWould you like to use the Legacy location?"
			if run_script 'question_prompt' "Y" "${PromptMessage}" "Multiple Compose Folders Detected" "" "Legacy" "Default"; then
				notice \
					"Chose the Legacy compose folder location:" \
					"   '${C["Folder"]-}${ExpandedLegacyComposeFolder}${NC-}'"
				set_toml_val "${APPLICATION_TOML_FILE}" "paths.compose_folder" "${LegacyComposeFolder}"
			else
				notice \
					"Chose the Default compose folder location:" \
					"   '${C["Folder"]-}${ExpandedDefaultComposeFolder}${NC-}'"
			fi
		elif [[ ${LegacyHasFiles} == true ]]; then
			set_toml_val "${APPLICATION_TOML_FILE}" "paths.compose_folder" "${LegacyComposeFolder}"
		fi
	fi

	notice ""
	notice "$(run_script 'config_show')"
	notice ""
}

test_config_create() {
	warn "CI does not test create_config."
}
