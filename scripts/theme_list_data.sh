#!/usr/bin/env bash
theme_list_data() {
	# Outputs one line per theme for TUI: "URI|DisplayName"
	# Embedded themes first, user themes appended.
	# If a user theme's display name collides with an embedded name, it is
	# shown as "user:Name" to disambiguate.

	local -a EmbeddedNames=()
	local -A EmbeddedDisplayNames=()

	# 1. Collect embedded themes
	local ThemeFile
	local -a EmbeddedFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${EmbeddedFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local Stem="${ThemeFile##*/}"
		Stem="${Stem%"${THEME_FILE_EXT}"}"

		# Extract metadata from TOML
		local ExtractedFile
		ExtractedFile=$(mktemp -t "${APPLICATION_NAME}.theme_list_data.XXXXXXXXXX")
		hrx_extract_file "${ThemeFile}" "${THEME_FILE_NAME}" "${ExtractedFile}"

		local DisplayName
		DisplayName="$(get_toml_val_string "${ExtractedFile}" "metadata.name")"
		[[ -z ${DisplayName} ]] && DisplayName="${Stem}"
		rm -f "${ExtractedFile}"

		EmbeddedNames+=("${Stem}")
		EmbeddedDisplayNames["${Stem}"]="${DisplayName}"
		echo "${DisplayName}|${Stem}|false"
	done

	# 2. Collect user themes, disambiguating name collisions
	local -a UserFiles=("${USER_THEMES_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${UserFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local Stem="${ThemeFile##*/}"
		Stem="${Stem%"${THEME_FILE_EXT}"}"

		# Extract metadata from TOML
		local ExtractedFile
		ExtractedFile=$(mktemp -t "${APPLICATION_NAME}.theme_list_data_user.XXXXXXXXXX")
		hrx_extract_file "${ThemeFile}" "${THEME_FILE_NAME}" "${ExtractedFile}"

		local DisplayName
		DisplayName="$(get_toml_val_string "${ExtractedFile}" "metadata.name")"
		[[ -z ${DisplayName} ]] && DisplayName="${Stem}"
		rm -f "${ExtractedFile}"

		# Check for collision with any embedded display name
		local Collides=false
		local EmbStem
		for EmbStem in "${EmbeddedNames[@]-}"; do
			if [[ ${EmbeddedDisplayNames["${EmbStem}"]} == "${DisplayName}" ]]; then
				Collides=true
				break
			fi
		done
		if [[ ${Collides} == true ]]; then
			DisplayName="user:${DisplayName}"
		fi
		echo "${DisplayName}|user:${Stem}|true"
	done
}
test_theme_list_data() {
	run_script 'theme_list_data'
}
