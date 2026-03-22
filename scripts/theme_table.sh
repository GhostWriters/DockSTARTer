#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_table() {
	local -a TableArray=()
	# 1. Collect embedded themes
	local -a EmbeddedFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${EmbeddedFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local ThemeName="${ThemeFile##*/}"
		ThemeName="${ThemeName%"${THEME_FILE_EXT}"}"
		local ThemeDescription ThemeAuthor
		ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
		ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"
		TableArray+=("${ThemeName}" "${ThemeDescription}" "${ThemeAuthor}")
	done

	# 2. Collect user themes
	local -a UserFiles=("${USER_THEMES_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${UserFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local ThemeName="${ThemeFile##*/}"
		ThemeName="${ThemeName%"${THEME_FILE_EXT}"}"
		local ThemeDescription ThemeAuthor
		# Prefix with user: so it can be passed to --theme or used in config
		local ConfigName="user:${ThemeName}"
		ThemeDescription="$(run_script 'theme_description' "${ConfigName}")"
		ThemeAuthor="$(run_script 'theme_author' "${ConfigName}")"
		TableArray+=("${ConfigName}" "${ThemeDescription}" "${ThemeAuthor}")
	done
	table 3 "Theme" "Description" "Author" "${TableArray[@]}"
}

test_theme_table() {
	run_script 'theme_table'
}
