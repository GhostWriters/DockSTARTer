#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
	if [[ ${CI-} == true ]]; then
		return
	fi

	local Title="Configuration Menu"

	if run_script 'needs_appvars_create'; then
		coproc {
			dialog_pipe "{{|TitleSuccess|}}Creating environment variables for added apps" "Please be patient, this can take a while.\n{{|CommandLine|}} ${APPLICATION_COMMAND} --env" "${DIALOGTIMEOUT}"
		}
		local -i DialogBox_PID=${COPROC_PID}
		local -i DialogBox_FD="${COPROC[1]}"
		{
			run_script 'env_backup'
			run_script 'appvars_create_all' || true
		} >&${DialogBox_FD} 2>&1
		exec {DialogBox_FD}<&-
		wait ${DialogBox_PID}
	fi

	local Option_FullSetup="Full Setup"
	local Option_EditGlobalVars="Edit Global Variables"
	local Option_SelectApps="Select Applications"
	local Option_EditAppVars="Configure Applications"
	local Option_ComposeUp="Start All Applications"
	local Option_ComposeDown="Stop All Applications"
	local Option_DockerPrune="Prune Docker System"
	local ConfigOpts=(
		"${Option_FullSetup}" "{{|ListDefault|}}This goes through selecting apps and editing variables. Recommended for first run" ""
		"${Option_EditGlobalVars}" "{{|ListDefault|}}Review and adjust global variables" ""
		"${Option_SelectApps}" "{{|ListDefault|}}Select which apps to run. Previously installed apps are remembered" ""
		"${Option_EditAppVars}" "{{|ListDefault|}}Review and adjust variables for installed apps" ""
		"${Option_ComposeUp}" "{{|ListDefault|}}Run Docker Compose to start all applications" ""
		"${Option_ComposeDown}" "{{|ListDefault|}}Run Docker Compose to stop all applications" ""
		"${Option_DockerPrune}" "{{|ListDefault|}}Remove all unused containers, networks, volumes, images and build cache" ""
	)

	local LastConfigChoice=""
	while true; do
		local -a ConfigChoiceDialog=(
			"${Title}"
			"What would you like to do?"
			--item-help
			"--ok-label:Select"
			"--extra-label:Back"
			"--cancel-label:Exit"
			"--default-item:${LastConfigChoice}"
			"${ConfigOpts[@]}"
		)
		local ConfigChoice
		local -i ConfigDialogButtonPressed=0
		ConfigChoice=$(dialog_menu "${ConfigChoiceDialog[@]}") || ConfigDialogButtonPressed=$?
		LastConfigChoice=${ConfigChoice}
		case ${DIALOG_BUTTONS[ConfigDialogButtonPressed]-} in
			OK) # Select
				case "${ConfigChoice}" in
					"${Option_FullSetup}")
						run_script 'menu_config_vars' || true
						run_script 'menu_app_select' || true
						run_script 'menu_config_apps' || true
						;;
					"${Option_EditGlobalVars}")
						run_script 'menu_config_vars' || true
						;;
					"${Option_SelectApps}")
						run_script 'menu_app_select' || true
						;;
					"${Option_EditAppVars}")
						run_script 'menu_config_apps' || true
						;;
					"${Option_ComposeUp}")
						run_script 'docker_compose' "update"
						;;
					"${Option_ComposeDown}")
						local Question
						Question="Would you like to {{|Highlight|}}Stop{{[-]}} all containers, or bring all containers {{|Highlight|}}Down{{[-]}}?\n\n{{|Highlight|}}Stop{{[-]}} will stop them, {{|Highlight|}}Down{{[-]}} will stop and remove them."
						set_screen_size
						local -a YesNoDialog=(
							"Docker Compose"
							"${Question}{{[-]}}"
							--maximized
							--no-collapse
							--extra-button
							--yes-label:Stop
							--extra-label:Down
							--cancel-label:Cancel
						)
						local -i YesNoDialogButtonPressed=0
						dialog_yesno "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
						case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
							OK) # Stop
								run_script_dialog "{{|TitleSuccess|}}Docker Compose" "Stopping all running services.\n{{|CommandLine|}} ${APPLICATION_COMMAND} --compose stop" "" \
									'docker_compose' "stop"
								;;
							EXTRA) # Down
								run_script_dialog "{{|TitleSuccess|}}Docker Compose" "Stopping and removing all containers, networks, volumes, and images.\n{{|CommandLine|}} ${APPLICATION_COMMAND} --compose down" "" \
									'docker_compose' "down"
								;;
							CANCEL | ESC) # Cancel
								;;
							*)
								invalid_dialog_button ${YesNoDialogButtonPressed}
								;;
						esac
						;;
					"${Option_DockerPrune}")
						run_script 'docker_prune'
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
				invalid_dialog_button ${ConfigDialogButtonPressed}
				;;
		esac
	done
}

test_menu_config() {
	# run_script 'menu_config'
	warn "CI does not test menu_config."
}
