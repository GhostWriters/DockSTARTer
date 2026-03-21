#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_show() {
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
		Value="$(get_toml_val "${APPLICATION_TOML_FILE}" "${Key}")"

		local ExpandedValue=""
		if [[ ${Key} == "paths.config_folder" || ${Key} == "paths.compose_folder" ]]; then
			ExpandedValue="$(
				expand_vars "${Value}" \
					HOME "${DETECTED_HOMEDIR}" \
					ScriptFolder "${SCRIPTPATH}" \
					XDG_CONFIG_HOME "${XDG_CONFIG_HOME}"
			)"
		fi

		local ValueColor="{{|Var|}}"
		if [[ ${Key} == "paths.config_folder" || ${Key} == "paths.compose_folder" ]]; then
			ValueColor="{{|Folder|}}"
		fi

		local DisplayValue="${ValueColor}${Value}{{[-]}}"
		local DisplayExpandedValue=""
		if [[ -n ${ExpandedValue} ]]; then
			DisplayExpandedValue="${ValueColor}${ExpandedValue}{{[-]}}"
		fi

		TableArray+=("${DisplayNames[${Key}]}" "${DisplayValue}" "${DisplayExpandedValue}")
	done

	resolve_strings C "Configuration options stored in '{{|File|}}${APPLICATION_TOML_FILE}{{[-]}}':"
	table 3 \
		"{{|UsageCommand|}}Option{{[-]}}" "{{|UsageCommand|}}Value{{[-]}}" "{{|UsageCommand|}}Expanded Value{{[-]}}" \
		"${TableArray[@]}"
}

test_config_show() {
	run_script 'config_show'
}
