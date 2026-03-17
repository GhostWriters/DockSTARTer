#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_exists() {
	local ThemeName=${1-}

	local ThemeArchive="${THEME_FOLDER}/${ThemeName}${THEME_FILE_EXT}"

	[[ -f ${ThemeArchive} ]]
}

test_theme_exists() {
	warn "CI does not test theme_exists."
}
