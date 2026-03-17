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

		local ValueColor="${C["Var"]-}"
		if [[ ${Key} == "paths.config_folder" || ${Key} == "paths.compose_folder" ]]; then
			ValueColor="${C["Folder"]-}"
		fi

		local DisplayValue="${ValueColor}${Value}${NC-}"
		local DisplayExpandedValue=""
		if [[ -n ${ExpandedValue} ]]; then
			DisplayExpandedValue="${ValueColor}${ExpandedValue}${NC-}"
		fi

		TableArray+=("${DisplayNames[${Key}]}" "${DisplayValue}" "${DisplayExpandedValue}")
	done

	echo "Configuration options stored in '${C["File"]}${APPLICATION_TOML_FILE}${NC}':"
	table 3 \
		"${C["UsageCommand"]}Option${NC}" "${C["UsageCommand"]}Value${NC}" "${C["UsageCommand"]}Expanded Value${NC}" \
		"${TableArray[@]}"
}

test_config_show() {
	run_script 'config_show'
}
