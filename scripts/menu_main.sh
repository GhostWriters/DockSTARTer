#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_main() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Main Menu"
	local Option_Configure="Configuration"
	local Option_InstallDependencies="Install Dependencies"
	local Option_UpdateVersion="Update ${APPLICATION_NAME}"
	local Option_Options="Options"
	local MainOpts=(
		"${Option_Configure}" "{{|ListDefault|}}Setup and start applications" ""
		"${Option_InstallDependencies}" "{{|ListDefault|}}Install required components" ""
		"${Option_UpdateVersion}" "{{|ListDefault|}}Get the latest version of ${APPLICATION_NAME}" ""
		"${Option_Options}" "{{|ListDefault|}}Adjust options for ${APPLICATION_NAME}" ""
	)

	local LastMainChoice=""
	while true; do
		local -a MainChoiceDialog=(
			"${Title}"
			"What would you like to do?"
			"--ok-label:Select"
			"--cancel-label:Exit"
			"--default-item:${LastMainChoice}"
			--item-help
			"${MainOpts[@]}"
		)
		local MainChoice
		local -i MainDialogButtonPressed=0
		MainChoice=$(dialog_menu "${MainChoiceDialog[@]}") || MainDialogButtonPressed=$?
		LastMainChoice=${MainChoice}
		case ${DIALOG_BUTTONS[MainDialogButtonPressed]-} in
			OK)
				case "${MainChoice}" in
					"${Option_Configure}")
						run_script 'menu_config' || true
						;;
					"${Option_InstallDependencies}")
						run_script 'run_install' || true
						;;
					"${Option_UpdateVersion}")
						run_script 'update_templates' || true
						run_script 'update_self' "" "${CURRENT_FLAGS_ARRAY[@]}" --menu "${REST_OF_ARGS_ARRAY[@]}" || true
						;;
					"${Option_Options}")
						run_script 'menu_options' || true
						;;
					*)
						error "Invalid Option"
						;;
				esac
				;;
			CANCEL | ESC)
				reset -Q || clear
				info "Exiting ${APPLICATION_NAME}."
				exit 0
				;;
			*)
				invalid_dialog_button ${MainDialogButtonPressed}
				;;
		esac
	done
}

test_menu_main() {
	# run_script 'menu_main'
	warn "CI does not test menu_main."
}
