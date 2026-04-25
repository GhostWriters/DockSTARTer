#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_show() {
	local ConfigFile=${1:-${APPLICATION_TOML_FILE}}
	local DefaultTitle="Configuration options stored in '{{|File|}}${ConfigFile}{{[-]}}':"
	local ConfigTitle=${2-${DefaultTitle}}

	local -a Keys=(
		"paths.config_folder"
		"paths.compose_folder"
		"pm.package_manager"
		"ui.theme"
		"ui.borders"
		"ui.line_characters"
		"ui.scrollbar"
		"ui.shadow"
	)

	local -A DisplayNames=(
		["paths.config_folder"]="Config Folder"
		["paths.compose_folder"]="Compose Folder"
		["pm.package_manager"]="Package Manager"
		["ui.theme"]="Theme"
		["ui.borders"]="Borders"
		["ui.line_characters"]="Line Characters"
		["ui.scrollbar"]="Scrollbar"
		["ui.shadow"]="Shadow"
	)

	local -a TableArray=()
	for Key in "${Keys[@]}"; do
		local Value
		if ! Value="$(run_script 'config_get' "${Key}" "${ConfigFile}")"; then
			continue
		fi
		local ValueColor ExpandedValue
		case ${Key} in
			paths.config_folder | paths.compose_folder)
				ValueColor="{{|Folder|}}"
				ExpandedValue="$(
					expand_vars "${Value}" \
						HOME "${DETECTED_HOMEDIR}" \
						ScriptFolder "${SCRIPTPATH}" \
						XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
				)"
				;;
			*)
				ValueColor="{{|Var|}}"
				ExpandedValue=""
				;;
		esac

		local DisplayValue="${ValueColor}${Value}{{[-]}}"
		local DisplayExpandedValue=""
		if [[ -n ${ExpandedValue} ]]; then
			DisplayExpandedValue="${ValueColor}${ExpandedValue}{{[-]}}"
		fi

		TableArray+=("${DisplayNames[${Key}]}" "${DisplayValue}" "${DisplayExpandedValue}")
	done

	if [[ -n ${ConfigTitle} ]]; then
		if [[ -t 1 ]]; then
			# Direct CLI call: Resolve now
			resolve_strings C "${ConfigTitle}"
		else
			# Captured for a notice: Output raw tags
			printf '%s\n' "${ConfigTitle}"
		fi
	fi

	table 3 \
		"{{|UsageCommand|}}Option{{[-]}}" "{{|UsageCommand|}}Value{{[-]}}" "{{|UsageCommand|}}Expanded Value{{[-]}}" \
		"${TableArray[@]}"
}

test_config_show() {
	run_script 'config_show'
}
