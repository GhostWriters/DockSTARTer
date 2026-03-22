#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_list() {
	local -a ThemeFiles=()
	ThemeFiles+=("${THEME_FOLDER}/"*"${THEME_FILE_EXT}")
	if [[ -d ${USER_THEMES_FOLDER} ]]; then
		ThemeFiles+=("${USER_THEMES_FOLDER}/"*"${THEME_FILE_EXT}")
	fi

	local File
	for File in "${ThemeFiles[@]-}"; do
		[[ -f ${File} ]] || continue
		local Stem
		Stem="$(basename "${File}" "${THEME_FILE_EXT}")"
		if [[ ${File} == "${USER_THEMES_FOLDER}/"* ]]; then
			echo "user:${Stem}"
		else
			echo "${Stem}"
		fi
	done
}

test_theme_list() {
	run_script 'theme_list'
}
