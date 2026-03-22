#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_table() {
	local -a TableArray=()
	local -a ThemeFiles=()
	ThemeFiles+=("${THEME_FOLDER}/"*"${THEME_FILE_EXT}")
	if [[ -d ${USER_THEMES_FOLDER} ]]; then
		ThemeFiles+=("${USER_THEMES_FOLDER}/"*"${THEME_FILE_EXT}")
	fi

	local File
	for File in "${ThemeFiles[@]-}"; do
		[[ -f ${File} ]] || continue
		local Stem URI
		Stem="$(basename "${File}" "${THEME_FILE_EXT}")"
		if [[ ${File} == "${USER_THEMES_FOLDER}/"* ]]; then
			URI="user:${Stem}"
		else
			URI="${Stem}"
		fi

		# Metadata extraction scripts handle URI/Names
		local ThemeDescription ThemeAuthor
		ThemeDescription="$(run_script 'theme_description' "${URI}")"
		ThemeAuthor="$(run_script 'theme_author' "${URI}")"
		TableArray+=("${URI}" "${ThemeDescription}" "${ThemeAuthor}")
	done
	table 3 "Theme" "Description" "Author" "${TableArray[@]}"
}

test_theme_table() {
	run_script 'theme_table'
}
