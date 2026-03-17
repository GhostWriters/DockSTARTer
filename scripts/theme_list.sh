#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list() {
	local -a ThemeFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${ThemeFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local ThemeName="${ThemeFile##*/}"
		ThemeName="${ThemeName%"${THEME_FILE_EXT}"}"
		echo "${ThemeName}"
	done
}

test_theme_list() {
	run_script 'theme_list'
}
