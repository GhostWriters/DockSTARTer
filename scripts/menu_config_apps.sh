#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_apps() {
	local Title="Configure Applications"

	local AddAplicationText='<ADD APPLICATION>'

	local LastAppChoice=""
	while true; do
		local AddedApps
		AddedApps="$(run_script 'app_list_referenced' | run_script 'app_nicename_pipe')"
		local -a AppOptions=()
		for AppName in ${AddedApps}; do
			local AppDescription
			AppDescription=$(run_script 'app_description' "${AppName}")
			if run_script 'app_is_user_defined' "${AppName}"; then
				AppOptions+=("${AppName}" "{{|ListAppUserDefined|}}${AppDescription}")
			else
				AppOptions+=("${AppName}" "{{|ListApp|}}${AppDescription}")
			fi
		done
		AppOptions+=("${AddAplicationText}" "")
		local -a AppChoiceDialog=(
			"${Title}"
			"Select the application to configure"
			--ok-label:Select
			--extra-label:Back
			--cancel-label:Exit
			--default-item:"${LastAppChoice}"
			"${AppOptions[@]}"
		)
		local AppChoice
		local -i AppChoiceButtonPressed=0
		AppChoice=$(dialog_menu "${AppChoiceDialog[@]}") || AppChoiceButtonPressed=$?
		LastAppChoice=${AppChoice}
		case ${DIALOG_BUTTONS[AppChoiceButtonPressed]-} in
			OK) # Select
				if [[ ${AppChoice} == "${AddAplicationText}" ]]; then
					run_script 'menu_add_app'
				else
					run_script 'menu_config_vars' "${AppChoice}"
				fi
				;;
			EXTRA | ESC) # Back
				return
				;;
			CANCEL) # Exit
				run_script 'menu_exit'
				;;
			*)
				invalid_dialog_button ${AppChoiceButtonPressed}
				;;
		esac
	done
}

test_menu_config_apps() {
	# run_script 'menu_config_apps'
	warn "CI does not test menu_config_apps."
}
