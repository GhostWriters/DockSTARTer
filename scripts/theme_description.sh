#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_description() {
	local ThemeName=${1-}

	if [[ -z ${ThemeName} ]]; then
		ThemeName="$(run_script 'theme_name')"
	fi

	local ThemeArchive
	if [[ ${ThemeName} == file:* ]]; then
		ThemeArchive="${ThemeName#file:}"
	elif [[ ${ThemeName} == user:* ]]; then
		ThemeArchive="${USER_THEMES_FOLDER}/${ThemeName#user:}${THEME_FILE_EXT}"
	else
		ThemeArchive="${THEME_FOLDER}/${ThemeName}${THEME_FILE_EXT}"
	fi

	hrx_toml_get "${ThemeArchive}" "${THEME_FILE_NAME}" "metadata.description"
}

test_theme_description() {
	run_script 'config_theme'
	run_script 'theme_description'
}
