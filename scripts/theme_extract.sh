#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_extract() {
	# theme_extract <ThemeNameOrURI> [DestDir] [FileName]
	# Extracts the .dstheme archive to DestDir/FileName.
	# DestDir defaults to the current directory.
	# FileName defaults to <stem>.dstheme.
	local ThemeName=${1-}
	local DestDir=${2:-.}
	[[ ${DestDir} == "user:" ]] && DestDir="${USER_THEMES_FOLDER}"
	local FileName=${3-}

	if [[ -z ${ThemeName} ]]; then
		error "theme_extract requires a theme name or user: URI."
		exit 1
	fi

	local ThemeArchive
	if [[ ${ThemeName} == user:* ]]; then
		local Stem="${ThemeName#user:}"
		ThemeArchive="${USER_THEMES_FOLDER}/${Stem}${THEME_FILE_EXT}"
		[[ -z ${FileName} ]] && FileName="${Stem}${THEME_FILE_EXT}"
	else
		ThemeArchive="${THEME_FOLDER}/${ThemeName}${THEME_FILE_EXT}"
		[[ -z ${FileName} ]] && FileName="${ThemeName}${THEME_FILE_EXT}"
	fi

	if [[ ! -f ${ThemeArchive} ]]; then
		error "Theme '{{|Theme|}}${ThemeName}{{[-]}}' not found."
		exit 1
	fi

	mkdir -p "${DestDir}"
	local Dest="${DestDir}/${FileName}"
	cp "${ThemeArchive}" "${Dest}"
	notice "Theme '{{|Theme|}}${ThemeName}{{[-]}}' extracted to: {{|File|}}${Dest}{{[-]}}"
}

test_theme_extract() {
	warn "CI does not test theme_extract."
}
