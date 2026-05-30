#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_app() {
	local Title="Add Application"

	local AppNameNone="{{|Highlight|}}[*NONE*]"

	local AppName=""
	#local BaseAppName InstanceName
	while true; do
		set_screen_size
		local AppNameHeading="${AppName}"
		if ! run_script 'appname_is_valid' "${AppName}"; then
			AppNameHeading="${AppNameNone}"
		fi
		local Heading InputValueText
		run_script 'menu_heading_into' Heading "${AppNameHeading}"
		InputValueText="${Heading}\n\nWhat application would you like add?\n"
		local -a InputValueDialog=(
			"${Title}"
			"${InputValueText}"
			--maximized
			--ok-label:Select
			--cancel-label:Back
			--exit-button
			"${AppName}"
		)
		local InputValueDialogButtonPressed=0
		AppName=$(tui_inputbox "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
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
					run_script 'app_nicename_into' AppName "${AppName}"
					AppNameHeading="${AppName}"
				else
					AppNameHeading="${AppNameNone}"
					ErrorMessage="The application name {{|Highlight|}}${AppName}{{[-]}} is not a valid name.\n\n Please input another application name."
				fi
				if [[ -n ${ErrorMessage} ]]; then
					run_script 'menu_heading_into' Heading "${AppNameHeading}"
					tui_error "${Title}" "${Heading}\n\n${ErrorMessage}"
					continue
				fi
				run_script 'menu_heading_into' Heading "${AppNameHeading}"
				if ! run_script 'app_is_builtin' "${AppName}"; then
					local Question
					Question="Create user defined application {{|Highlight|}}${AppName}{{[-]}}?\n"
					run_script 'menu_heading_into' Heading "${AppNameHeading}"
					if run_script 'question_prompt' N "${Heading}\n\n${Question}" "Create Application" "${ASSUMEYES:+Y}" "User Defined" "Back"; then
						run_script 'menu_heading_into' Heading "${AppNameHeading}"
						tui_success "Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
						run_script 'menu_add_var' "${AppName}"
						return
					fi
				else
					local Question
					Question="Application {{|Highlight|}}${AppName}{{[-]}} can be added as a built-in application.\n\nCreate {{|Highlight|}}${AppName}{{[-]}} as a {{|Highlight|}}Built In{{[-]}} or a {{|Highlight|}}User Defined{{[-]}} application?\n"
					run_script 'menu_heading_into' Heading "${AppNameHeading}"
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
					tui_yesno "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
					case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
						OK) # Built In
							run_script 'menu_heading_into' Heading "${AppNameHeading}"
							#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
							local -i PipeFD PipePID
							tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}Adding Built In Application" "${Heading}\n\n{{|Subtitle|}}Adding application:\n{{|CommandLine|}} ${APPLICATION_COMMAND} --add ${AppName}" "${DIALOGTIMEOUT}"
							{
								run_script 'env_backup'
								run_script 'appvars_create' "${AppName}"
								run_script 'env_update'
							} >&${PipeFD} 2>&1
							tui_pipe_close PipeFD PipePID
							return
							;;
						EXTRA) # User Defined
							run_script 'menu_heading_into' Heading "${AppNameHeading}"
							tui_success "{{|TitleSuccess|}}Adding User Defined Application" "${Heading}" "${DIALOGTIMEOUT}"
							run_script 'menu_add_var' "${AppName}"
							return
							;;
						CANCEL | ESC) # Back
							;;
						*)
							invalid_tui_button ${YesNoDialogButtonPressed}
							;;
					esac
				fi
				;;
			CANCEL | ESC)
				return
				;;
			EXIT)
				run_script 'menu_exit'
				continue
				;;
			*)
				invalid_tui_button ${InputValueDialogButtonPressed}
				;;
		esac
	done
}
test_menu_add_app() {
	warn "CI does not test menu_add_app."
}
