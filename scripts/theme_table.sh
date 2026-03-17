#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_table() {
	local -a TableArray=()
	local -a ThemeFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${ThemeFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local ThemeName="${ThemeFile##*/}"
		ThemeName="${ThemeName%"${THEME_FILE_EXT}"}"
		local ThemeDescription ThemeAuthor
		ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
		ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"
		TableArray+=("${ThemeName}" "${ThemeDescription}" "${ThemeAuthor}")
	done
	table 3 "Theme" "Description" "Author" "${TableArray[@]}"
}

test_theme_table() {
	run_script 'theme_table'
}
