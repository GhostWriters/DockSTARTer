#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

theme_extract_all() {
	# theme_extract_all [DestDir]
	# Extracts all embedded themes to DestDir (default: current directory).
	local DestDir=${1:-.}
	[[ ${DestDir} == "user:" ]] && DestDir="${USER_THEMES_FOLDER}"
	mkdir -p "${DestDir}"

	local -i Extracted=0
	local -a ThemeFiles=("${THEME_FOLDER}"/*"${THEME_FILE_EXT}")
	for ThemeFile in "${ThemeFiles[@]-}"; do
		[[ -f ${ThemeFile} ]] || continue
		local FileName="${ThemeFile##*/}"
		local Dest="${DestDir}/${FileName}"
		if cp "${ThemeFile}" "${Dest}" 2> /dev/null; then
			notice "  Extracted: {{|Theme|}}${FileName}{{[-]}}"
			Extracted+=1
		else
			warn "Failed to extract '{{|Theme|}}${FileName}{{[-]}}' to '{{|Folder|}}${DestDir}{{[-]}}'."
		fi
	done
	notice "${Extracted} theme(s) extracted to: {{|Folder|}}${DestDir}{{[-]}}"
}

test_theme_extract_all() {
	warn "CI does not test theme_extract_all."
}
