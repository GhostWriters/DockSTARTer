#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_options() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Options"
	local Option_Theme="Choose Theme"
	local Option_Display="Display Options"
	local Option_Package_Manager="Package Manager"
	local Opts=(
		"${Option_Theme}" "{{|ListDefault|}}Choose a theme for ${APPLICATION_NAME}" ""
		"${Option_Display}" "{{|ListDefault|}}Set display options" ""
		"${Option_Package_Manager}" "{{|ListDefault|}}Choose the package manager to use" ""
	)

	local LastChoice=""
	while true; do
		local -a ChoiceDialog=(
			"${Title}"
			"What would you like to do?"
			"--ok-label:Select"
			"--extra-label:Back"
			"--cancel-label:Exit"
			"--default-item:${LastChoice}"
			--item-help
			"${Opts[@]}"
		)
		local Choice
		local -i DialogButtonPressed=0
		Choice=$(dialog_menu "${ChoiceDialog[@]}") || DialogButtonPressed=$?
		LastChoice=${Choice}
		case ${DIALOG_BUTTONS[DialogButtonPressed]-} in
			OK) # Select
				case "${Choice}" in
					"${Option_Theme}")
						run_script 'menu_options_theme' || true
						;;
					"${Option_Display}")
						run_script 'menu_options_display' || true
						;;
					"${Option_Package_Manager}")
						run_script 'menu_options_package_manager' || true
						;;
					*)
						error "Invalid Option"
						;;
				esac
				;;
			EXTRA | ESC) # Back
				return
				;;
			CANCEL) # Exit
				run_script 'menu_exit'
				;;
			*)
				invalid_dialog_button ${DialogButtonPressed}
				;;
		esac
	done
}

test_menu_options() {
	warn "CI does not test menu_options."
}
