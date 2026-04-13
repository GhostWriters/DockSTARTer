#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_exists() {
	local ThemeName=${1-}

	local ThemeArchive
	if [[ ${ThemeName} == file:* ]]; then
		ThemeArchive="${ThemeName#file:}"
	elif [[ ${ThemeName} == user:* ]]; then
		ThemeArchive="${USER_THEMES_FOLDER}/${ThemeName#user:}${THEME_FILE_EXT}"
	else
		ThemeArchive="${THEME_FOLDER}/${ThemeName}${THEME_FILE_EXT}"
	fi

	[[ -f ${ThemeArchive} ]]
}

test_theme_exists() {
	warn "CI does not test theme_exists."
}
