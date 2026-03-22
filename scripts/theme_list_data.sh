#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list_data() {
	# Outputs one line per theme: "DisplayName|ConfigValue|IsUserTheme"
	# Embedded themes first, user themes appended.
	# If a user theme's display name collides with an embedded name, it is
	# shown as "user:Name" to disambiguate.

	local -a EmbeddedNames=()
	local -A EmbeddedDisplayNames=()

	# 1. Collect embedded themes
	local -a EmbeddedFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${EmbeddedFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local Stem="${ThemeFile##*/}"
		Stem="${Stem%"${THEME_FILE_EXT}"}"
		local DisplayName
		DisplayName="$(hrx_toml_get "${ThemeFile}" "${THEME_FILE_NAME}" "metadata.name")"
		[[ -z ${DisplayName} ]] && DisplayName="${Stem}"
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
		local DisplayName
		DisplayName="$(hrx_toml_get "${ThemeFile}" "${THEME_FILE_NAME}" "metadata.name")"
		[[ -z ${DisplayName} ]] && DisplayName="${Stem}"
		# Check for collision with any embedded display name
		local Collides=false
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

test_theme_list() {
	run_script 'theme_list'
}
