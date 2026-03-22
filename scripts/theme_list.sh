#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list() {
	# Outputs one line per theme (the theme name/stem).

	# 1. Collect embedded themes
	local -a EmbeddedFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${EmbeddedFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local Stem="${ThemeFile##*/}"
		Stem="${Stem%"${THEME_FILE_EXT}"}"
		echo "${Stem}"
	done

	# 2. Collect user themes
	local -a UserFiles=("${USER_THEMES_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${UserFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local Stem="${ThemeFile##*/}"
		Stem="${Stem%"${THEME_FILE_EXT}"}"
		echo "user:${Stem}"
	done
}

test_theme_list() {
	run_script 'theme_list'
}
