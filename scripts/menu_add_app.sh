#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_app() {
	local Title="Add Application"

	local AppNameMaxLength=256
	local AppNameNone="{{|Highlight|}}[*NONE*]"

	local AppName=""
	#local BaseAppName InstanceName
	while true; do
		set_screen_size
		local AppNameHeading="${AppName}"
		if ! run_script 'appname_is_valid' "${AppName}"; then
			AppNameHeading="${AppNameNone}"
		fi
		local InputValueText
		Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
		InputValueText="${Heading}\n\nWhat application would you like add?\n"
		local ValueOptions
		ValueOptions=(
			"" 1 1
			"${AppName}" 1 1
			"${AppNameMaxLength}" "${AppNameMaxLength}"
		)
		local -a InputValueDialog=(
			"${Title}"
			"${InputValueText}"
			--maximized
			--ok-label:Select
			"--extra-label:Back"
			--cancel-label:Exit
			"${ValueOptions[@]}"
		)
		local InputValueDialogButtonPressed=0
		AppName=$(dialog_form "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
		case ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} in
			OK)
				# Sanitize the input
				local CleanAppName
				CleanAppName="$(tr -c '[:alnum:]' ' ' <<< "${AppName}" | xargs)"
				if [[ -z ${CleanAppName//_/} ]]; then
					AppName=''
					continue
				fi
				BaseAppName="${CleanAppName%% *}"
				InstanceName="${CleanAppName#"${BaseAppName}"}"
				InstanceName="${InstanceName// /}"
				CleanAppName="${BaseAppName}"
				if [[ -n ${InstanceName} ]]; then
					CleanAppName+="__${InstanceName}"
				fi
				AppName="${CleanAppName}"

				local ErrorMessage=''
				if run_script 'appname_is_valid' "${AppName}"; then
					AppName="$(run_script 'app_nicename' "${AppName}")"
					AppNameHeading="${AppName}"
				else
					AppNameHeading="${AppNameNone}"
					ErrorMessage="The application name {{|Highlight|}}${AppName}{{[-]}} is not a valid name.\n\n Please input another application name."
				fi
				if [[ -n ${ErrorMessage} ]]; then
					Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
					dialog_error "${Title}" "${Heading}\n\n${ErrorMessage}"
					continue
				fi
				Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
				if ! run_script 'app_is_builtin' "${AppName}"; then
					local Question
					Question="Create user defined application {{|Highlight|}}${AppName}{{[-]}}?\n"
					Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
					if run_script 'question_prompt' N "${Heading}\n\n${Question}" "Create Application" "${ASSUMEYES:+Y}" "User Defined" "Back"; then
						Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
						dialog_success "Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
						run_script 'menu_add_var' "${AppName}"
						return
					fi
				else
					local Question
					Question="Application {{|Highlight|}}${AppName}{{[-]}} can be added as a built-in application.\n\nCreate {{|Highlight|}}${AppName}{{[-]}} as a {{|Highlight|}}Built In{{[-]}} or a {{|Highlight|}}User Defined{{[-]}} application?\n"
					Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
					local -a YesNoDialog=(
						"${Title}"
						"${Heading}\n\n${Question}"
						--maximized
						--no-collapse
						"--yes-label:Built In"
						"--extra-label:User Defined"
						"--no-label:Back"
					)
					local -i YesNoDialogButtonPressed=0
					dialog_yesno "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
					case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
						OK) # Built In
							Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
							coproc {
								dialog_pipe "{{|TitleSuccess|}}Adding Built In Application" "${Heading}\n\n{{|Subtitle|}}Adding application:\n{{|CommandLine|}} ${APPLICATION_COMMAND} --add ${AppName}" "${DIALOGTIMEOUT}"
							}
							local -i DialogBox_PID=${COPROC_PID}
							local -i DialogBox_FD="${COPROC[1]}"
							{
								run_script 'env_backup'
								run_script 'appvars_create' "${AppName}"
								run_script 'env_update'
							} >&${DialogBox_FD} 2>&1
							exec {DialogBox_FD}<&-
							wait ${DialogBox_PID}
							return
							;;
						EXTRA) # User Defined
							Heading="$(run_script 'menu_heading' "${AppNameHeading}")"
							dialog_success "{{|TitleSuccess|}}Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
							run_script 'menu_add_var' "${AppName}"
							return
							;;
						CANCEL | ESC) # Back
							;;
						*)
							invalid_dialog_button ${YesNoDialogButtonPressed}
							;;
					esac
				fi
				;;
			EXTRA)
				return
				;;
			CANCEL | ESC)
				run_script 'menu_exit'
				continue
				;;
			*)
				invalid_dialog_button ${InputValueDialogButtonPressed}
				;;
		esac
	done
}
test_menu_add_app() {
	warn "CI does not test menu_add_app."
}
