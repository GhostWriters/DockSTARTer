#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

theme_table() {
	local -a TableArray=()
	local -a ThemeList
	readarray -t ThemeList < <(${FIND} "${THEME_FOLDER}" -maxdepth 1 -type d ! -path "${THEME_FOLDER}" -printf "%f\n" | sort)
	for ThemeName in "${ThemeList[@]-}"; do
		if run_script 'theme_exists' "${ThemeName}"; then
			local ThemeDescription ThemeAuthor
			ThemeDescription="$(run_script 'theme_description' "${ThemeName}")"
			ThemeAuthor="$(run_script 'theme_author' "${ThemeName}")"
			TableArray+=("${ThemeName}" "${ThemeDescription}" "${ThemeAuthor}")
		fi
	done
	table 3 "Theme" "Description" "Author" "${TableArray[@]}"
}

test_theme_table() {
	run_script 'theme_table'
}
