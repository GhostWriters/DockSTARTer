#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_author() {
	local ThemeName=${1-}

	if [[ -z ${ThemeName} ]]; then
		ThemeName="$(run_script 'theme_name')"
	fi

	local ThemeArchive
	if [[ ${ThemeName} == user:* ]]; then
		ThemeArchive="${USER_THEMES_FOLDER}/${ThemeName#user:}${THEME_FILE_EXT}"
	else
		ThemeArchive="${THEME_FOLDER}/${ThemeName}${THEME_FILE_EXT}"
	fi

	hrx_env_get "${ThemeArchive}" "${THEME_FILE_NAME}" "ThemeAuthor"
}

test_theme_author() {
	run_script 'config_theme'
	run_script 'theme_author'
}
