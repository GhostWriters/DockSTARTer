#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

menu_value_prompt() {
	local VarName=${1-}
	local CleanVarName="${VarName}"

	if [[ ${CI-} == true ]]; then
		return
	fi

	local APPNAME AppName

	local VarDeletedTag="{{|Highlight|}}[*DELETED*]"

	local Title
	local CleanVarName="${VarName}"

	local VarType

	local APPNAME
	run_script 'varname_to_appname_into' APPNAME "${VarName}"
	APPNAME="${APPNAME^^}"
	if [[ -n ${APPNAME} ]]; then
		Title="Edit Application Variable"
		if [[ ${VarName} == *":"* ]]; then
			VarType="APPENV"
			CleanVarName=${VarName#*:}
			VarName="${APPNAME}:${CleanVarName}"
		else
			VarType="APP"
		fi
		run_script 'app_nicename_into' AppName "${APPNAME}"
	else
		Title="Edit Global Variable"
		VarType="GLOBAL"
	fi

	local CurrentValueOption="Current Value"
	local DefaultValueOption="Default Value"
	local SystemValueOption="System Value"
	local OriginalValueOption="Original Value"

	local ValueDescription=""
	local -A OptionHelpLine=()
	local -A OptionValue=()
	run_script 'env_get_literal_into' OptionValue["${OriginalValueOption}"] "${VarName}"
	OptionHelpLine["${OriginalValueOption}"]="This is the original value before before entering the editor."
	OptionValue["${CurrentValueOption}"]="${OptionValue["${OriginalValueOption}"]}"
	OptionHelpLine["${CurrentValueOption}"]="This is the value that will be saved when you select Done."
	OptionHelpLine["${DefaultValueOption}"]="This is the recommended default value."
	OptionHelpLine["${SystemValueOption}"]="This is the recommended system detected value."
	local DeleteHelpLine="This will set the variable to be deleted when you select Done."

	local -a PossibleOptions=("${CurrentValueOption}")
	case "${VarType}" in
		GLOBAL)
			case "${VarName}" in
				DOCKER_GID)
					ValueDescription="\n\n This should be the Docker group ID. If you are unsure, select {{|Highlight|}}${SystemValueOption}{{[-]}}."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				DOCKER_HOSTNAME)
					ValueDescription="\n\n This should be your system hostname. If you are unsure, select {{|Highlight|}}${SystemValueOption}{{[-]}}."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				DOCKER_VOLUME_CONFIG)
					ValueDescription="\n\n The path where application {{|Highlight|}}config data{{[-]}} is stored."
					PossibleOptions+=(
						"Home Folder"
					)
					OptionValue+=(
						["Home Folder"]="'${DETECTED_HOMEDIR}/.config/appdata'"
					)
					;;
				DOCKER_VOLUME_STORAGE)
					ValueDescription="\n\n The path where application {{|Highlight|}}storage data{{[-]}} is stored."
					PossibleOptions+=(
						"Home Folder"
						"Mount Folder"
					)
					OptionValue+=(
						["Home Folder"]="'${DETECTED_HOMEDIR}/storage'"
						["Mount Folder"]="'/mnt/storage'"
					)
					;;
				GLOBAL_LAN_NETWORK)
					ValueDescription="\n\n This is used to define your home LAN network. Do NOT confuse this with the IP address of your router or your server — the value for this key defines your {{|Highlight|}}network{{[-]}}, NOT a single host. See CIDR Notation for more information (e.g. {{|Highlight|}}192.168.1.0/24{{[-]}})."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				PGID)
					ValueDescription="\n\n This should be your user group ID. If you are unsure, select {{|Highlight|}}${SystemValueOption}{{[-]}}."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				PUID)
					ValueDescription="\n\n This should be your user account ID. If you are unsure, select {{|Highlight|}}${SystemValueOption}{{[-]}}."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				TZ)
					ValueDescription="\n\n If this is not the correct timezone, please exit and set your {{|Highlight|}}system timezone{{[-]}} first."
					PossibleOptions+=(
						"${SystemValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${SystemValueOption}"]="${Default}"
					)
					;;
				*)
					ValueDescription=""
					PossibleOptions+=(
						"${DefaultValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
					)
					;;
			esac
			;;
		APP)
			case "${VarName}" in
				"${APPNAME}__ENABLED")
					ValueDescription="\n\n This is used to set the application as enabled or disabled. If this variable is removed, the application will not be controlled by ${APPLICATION_NAME}. Must be {{|Highlight|}}true{{[-]}} or {{|Highlight|}}false{{[-]}}."
					PossibleOptions+=(
						"Enabled"
						"Disabled"
						"${DefaultValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["Enabled"]="'true'"
						["Disabled"]="'false'"
						["${DefaultValueOption}"]="${Default}"
					)
					;;
				"${APPNAME}__NETWORK_MODE")
					ValueDescription="\n\n Network Mode is usually left blank but can also be {{|Highlight|}}bridge{{[-]}}, {{|Highlight|}}host{{[-]}}, {{|Highlight|}}none{{[-]}}, {{|Highlight|}}service:<appname>{{[-]}}, or {{|Highlight|}}container:<appname>{{[-]}}."
					PossibleOptions+=(
						"${DefaultValueOption}"
						"Bridge Network"
						"Host Network"
						"No Network"
						"Use Gluetun"
						"Use PrivoxyVPN"
					)
					OptionHelpLine+=(
						["Bridge Network"]="Connects {{|Highlight|}}${AppName}{{[-]}} to the internal Docker bridge network. Same as leaving the value empty."
						["Host Network"]="Connects {{|Highlight|}}${AppName}{{[-]}} to the host OS's network."
						["No Network"]="Leaves {{|Highlight|}}${AppName}{{[-]}} without a network connection."
						["Use Gluetun"]="Connects {{|Highlight|}}${AppName}{{[-]}} to the VPN running in the {{|Highlight|}}Gluetun{{[-]}} container if running."
						["Use PrivoxyVPN"]="Connects {{|Highlight|}}${AppName}{{[-]}} to the VPN running in the {{|Highlight|}}PrivoxyVPN{{[-]}} container if running."
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
						["Bridge Network"]="'bridge'"
						["Host Network"]="'host'"
						["No Network"]="'none'"
						["Use Gluetun"]="'service:gluetun'"
						["Use PrivoxyVPN"]="'service:privoxyvpn'"
					)
					;;
				"${APPNAME}__RESTART")
					ValueDescription="\n\n Restart is usually {{|Highlight|}}unless-stopped{{[-]}} but can also be {{|Highlight|}}no{{[-]}}, {{|Highlight|}}always{{[-]}}, or {{|Highlight|}}on-failure{{[-]}}."
					PossibleOptions+=(
						"${DefaultValueOption}"
						"Restart Unless Stopped"
						"Never Restart"
						"Always Restart"
						"Restart On Failure"
					)
					OptionHelpLine+=(
						["Restart Unless Stopped"]="This will cause the application to restart unless the user manually stopped it."
						["Never Restart"]="This will cause the application to never restart."
						["Always Restart"]="This will cause the application to always restart"
						["Restart On Failure"]="This will cause the application to restart if it stops due to a failure."
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
						["Restart Unless Stopped"]="'unless-stopped'"
						["Never Restart"]="'no'"
						["Always Restart"]="'always'"
						["Restart On Failure"]="'on-failure'"
					)
					;;
				"${APPNAME}__TAG")
					ValueDescription="\n\n Tag is usually latest but can also be other values based on the image."
					PossibleOptions+=(
						"${DefaultValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
					)
					;;
				"${APPNAME}__VOLUME_"*)
					ValueDescription="\n\n If the directory selected does not exist, DockSTARTer will attempt to create it."
					PossibleOptions+=(
						"${DefaultValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
					)
					;;
				*)
					if [[ ${VarName} =~ ^${APPNAME}__PORT_[0-9]+$ ]]; then
						ValueDescription="\n\n Must be an unused port between {{|Highlight|}}0{{[-]}} and {{|Highlight|}}65535{{[-]}}."
						PossibleOptions+=(
							"${DefaultValueOption}"
						)
						local Default
						run_script 'var_default_value_into' Default "${VarName}"
						OptionValue+=(
							["${DefaultValueOption}"]="${Default}"
						)
					else
						ValueDescription=""
						PossibleOptions+=(
							"${DefaultValueOption}"
						)
						local Default
						run_script 'var_default_value_into' Default "${VarName}"
						OptionValue+=(
							["${DefaultValueOption}"]="${Default}"
						)
					fi
					;;
			esac
			;;
		APPENV)
			case "${VarName}" in
				*)
					PossibleOptions+=(
						"${DefaultValueOption}"
					)
					local Default
					run_script 'var_default_value_into' Default "${VarName}"
					OptionValue+=(
						["${DefaultValueOption}"]="${Default}"
					)
					;;
			esac
			;;
	esac
	PossibleOptions+=("${OriginalValueOption}")

	if [[ -n ${OptionValue["${SystemValueOption}"]-} ]]; then
		ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
	fi

	while true; do
		local -a ValidOptions=()
		local -a ValueOptions=()
		local OptionsLength=0
		for Option in "${PossibleOptions[@]}"; do
			if [[ -n ${OptionValue["$Option"]-} ]] || [[ ${Option} == "${CurrentValueOption}" ]] || [[ ${Option} == "${OriginalValueOption}" ]]; then
				if [[ ${#Option} -gt OptionsLength ]]; then
					OptionsLength=${#Option}
				fi
				ValidOptions+=("${Option}")
				ValueOptions+=("${Option}" "${OptionValue["$Option"]}" "${OptionHelpLine["$Option"]-}")
			fi
		done
		local DeleteOption=" DELETE "
		local Bar
		Bar=$(printf "%$(((OptionsLength - ${#DeleteOption}) / 2))s" '' | tr ' ' '=')
		DeleteOption=" ${Bar}${DeleteOption}${Bar}"
		ValidOptions+=("${DeleteOption}")
		ValueOptions+=("${DeleteOption}" "" "${DeleteHelpLine-}")

		local ValidOptionsRegex
		local Old_IFS="${IFS}"
		IFS='|'
		ValidOptionsRegex="${ValidOptions[*]}"
		IFS="${Old_IFS}"

		local DialogHeading
		local CurrentValueHeading="${OptionValue["${CurrentValueOption}"]:-${VarDeletedTag}}"
		run_script 'menu_heading_into' DialogHeading "${APPNAME}" "${VarName}" "${OptionValue["${OriginalValueOption}"]-}" "${CurrentValueHeading}"
		local SelectValueMenuText="${DialogHeading}\n\nWhat would you like set for {{|Highlight|}}${CleanVarName}{{[-]}}?${ValueDescription}"
		local -a SelectValueDialog=(
			"${Title}"
			"${SelectValueMenuText}"
			--maximized
			--item-help
			--ok-label:Select
			--extra-label:Edit
			--cancel-label:Done
			"${ValueOptions[@]}"
		)
		local -i SelectValueDialogButtonPressed=0
		local SelectedValue
		SelectedValue=$(menu_value_prompt_select "${SelectValueDialog[@]}") || SelectValueDialogButtonPressed=$?

		case ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} in
			OK) # SELECT button
				if [[ ${SelectedValue} == "${DeleteOption}" ]]; then
					OptionValue["${CurrentValueOption}"]=""
				elif [[ ${SelectedValue} =~ ${ValidOptionsRegex} ]]; then
					if [[ -n ${OptionValue["${SelectedValue}"]-} ]]; then
						OptionValue["${CurrentValueOption}"]="${OptionValue["${SelectedValue}"]}"
					else
						error "Unset value '{{|Var|}}${SelectedValue}{{[-]}}'"
					fi
				else
					error "Invalid option '{{|Var|}}${SelectedValue}{{[-]}}'"
				fi
				;;
			EXTRA) # EDIT button
				OptionValue["${CurrentValueOption}"]=$(${GREP} -o -P "^RENAMED (${ValidOptionsRegex}) \K.*" <<< "${SelectedValue}" || true)
				;;
			CANCEL | ESC) # DONE button
				local ValueValid="false"
				if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
					# Value is empty, variable will be deleted
					ValueValid="true"
				elif [[ ${OptionValue["${CurrentValueOption}"]} == *"$"* ]]; then
					# Value contains a '$', assume it uses variable interpolation and allow it
					ValueValid="true"
				else
					local StrippedValue="${OptionValue["${CurrentValueOption}"]}"
					# Unqauote the value
					case "${StrippedValue}" in
						"'"*"'") StrippedValue="${StrippedValue:1:${#StrippedValue}-2}" ;;
						'"'*'"') StrippedValue="${StrippedValue:1:${#StrippedValue}-2}" ;;
					esac

					case "${VarName}" in
						"${APPNAME}__ENABLED")
							case "${StrippedValue^^}" in
								ON | TRUE | YES | OFF | FALSE | NO)
									ValueValid="true"
									;;
								*)
									ValueValid="false"
									tui_error "${Title}" "${DialogHeading}\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not {{|Highlight|}}true{{[-]}}/{{|Highlight|}}on{{[-]}}/{{|Highlight|}}yes{{[-]}} or {{|Highlight|}}false{{[-]}}/{{|Highlight|}}off{{[-]}}/{{|Highlight|}}no{{[-]}}. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
									;;
							esac
							;;
						"${APPNAME}__NETWORK_MODE")
							case "${StrippedValue}" in
								"" | "bridge" | "host" | "none" | "service:"* | "container:"*)
									ValueValid="true"
									;;
								*)
									ValueValid="false"
									tui_error "${Title}" "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid network mode. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
									;;
							esac
							;;
						"${APPNAME}__RESTART")
							case "${StrippedValue}" in
								"no" | "always" | "on-failure" | "unless-stopped")
									ValueValid="true"
									;;
								*)
									ValueValid="false"
									tui_error "${Title}" "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid restart value. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
									;;
							esac
							;;
						"${APPNAME}__VOLUME_"*)
							if [[ ${StrippedValue} == "/" ]]; then
								ValueValid="false"
								tui_error "${Title}" "${DialogHeading}\n\nCannot use {{|Highlight|}}/{{[-]}} for {{|Highlight|}}${CleanVarName}{{[-]}}. Please select another folder."
							elif [[ ${StrippedValue} == *~* ]]; then
								local CORRECTED_DIR="${OptionValue["${CurrentValueOption}"]//\~/"${DETECTED_HOMEDIR}"}"
								if run_script 'question_prompt' --maximized Y "${DialogHeading}\n\nCannot use the {{|Highlight|}}~{{[-]}} shortcut in {{|Highlight|}}${CleanVarName}{{[-]}}. Would you like to use {{|Highlight|}}${CORRECTED_DIR}{{[-]}} instead?" "${Title}"; then
									OptionValue["${CurrentValueOption}"]="${CORRECTED_DIR}"
									ValueValid="false"
									tui_success "${Title}" "Returning to the previous menu to confirm selection."
								else
									ValueValid="false"
									tui_error "${Title}" "${DialogHeading}\n\nCannot use the {{|Highlight|}}~{{[-]}} shortcut in {{|Highlight|}}${CleanVarName}{{[-]}}. Please select another folder."
								fi
							elif [[ -d ${StrippedValue} ]]; then
								if run_script 'question_prompt' --maximized Y "${DialogHeading}\n\nWould you like to set permissions on ${OptionValue["${CurrentValueOption}"]} ?" "${Title}" "${ASSUMEYES:+Y}"; then
									run_script_tui "Setting Permissions" "{{|Heading|}}${StrippedValue}{{[-]}}" "${DIALOGTIMEOUT}" \
										'set_permissions' "${StrippedValue}"
								fi
								ValueValid="true"
							else
								if run_script 'question_prompt' --maximized Y "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
									#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
									local -i PipeFD PipePID
									tui_pipe_open PipeFD PipePID "Creating folder and settings permissions" "${OptionValue["${CurrentValueOption}"]}" "${DIALOGTIMEOUT}"
									{
										{
											mkdir -p "${StrippedValue}" ||
												fatal \
													"Failed to make directory.\n" \
													"Failing command: {{|FailingCommand|}}mkdir -p \"${StrippedValue}\""
											run_script 'set_permissions' "${StrippedValue}"
										} || true
									} >&${PipeFD} 2>&1
									tui_pipe_close PipeFD PipePID
									tui_msgbox "{{|TitleSuccess|}}${Title}" "{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} folder was created successfully." --maximized
									ValueValid="true"
								else
									tui_error "${Title}" "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid path. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
									ValueValid="false"
								fi
							fi
							;;
						P[GU]ID)
							if [[ ${StrippedValue} =~ ^[0-9]+$ ]]; then
								if [[ ${StrippedValue} -eq 0 ]]; then
									if run_script 'question_prompt' --maximized Y "${DialogHeading}\n\nRunning as {{|Highlight|}}root{{[-]}} is not recommended. Would you like to select a different ID?" "${Title}" ""; then
										ValueValid="false"
									else
										ValueValid="true"
									fi
								else
									ValueValid="true"
								fi
							else
								tui_error "${Title}" "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid ${CleanVarName}. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
								ValueValid="false"
							fi
							;;
						*)
							if [[ ${VarName} =~ ^${APPNAME}__PORT_[0-9]+$ ]]; then
								if [[ ${StrippedValue} =~ ^[0-9]+$ ]] && [[ ${StrippedValue} -ge 0 ]] && [[ ${StrippedValue} -le 65535 ]]; then
									ValueValid="true"
								else
									ValueValid="false"
									tui_error "${Title}" "${DialogHeading}\n\n{{|Highlight|}}${OptionValue["${CurrentValueOption}"]}{{[-]}} is not a valid port. Please try setting {{|Highlight|}}${CleanVarName}{{[-]}} again."
								fi
							else
								ValueValid="true"
							fi
							;;
					esac
				fi
				if [[ ${ValueValid} == "true" ]]; then
					if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
						if run_script 'question_prompt' --maximized N "${DialogHeading}\n\nDo you really want to delete {{|Highlight|}}${CleanVarName}{{[-]}}?\n" "Delete Variable" "${ASSUMEYES:+Y}" "Delete" "Back"; then
							# Value is empty, delete the variable
							#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
							local -i PipeFD PipePID
							tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}Deleting Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
							{
								run_script 'env_delete' "${VarName}"
								if [[ -n ${APPNAME-} ]]; then
									if ! run_script 'app_is_user_defined' "${APPNAME}"; then
										run_script 'env_backup'
										run_script 'appvars_create' "${APPNAME}"
										run_script 'env_update'
										run_script 'env_sanitize'
									fi
								else
									run_script 'env_backup'
									run_script 'appvars_migrate_enabled_lines'
									run_script 'env_sanitize'
									run_script 'env_update'
								fi
							} >&${PipeFD} 2>&1 || true
							tui_pipe_close PipeFD PipePID
							return 0
						fi
					elif [[ ${OptionValue["${CurrentValueOption}"]-} == "${OptionValue["${OriginalValueOption}"]-}" ]]; then
						if run_script 'question_prompt' --maximized N "${DialogHeading}\n\nThe value of {{|Highlight|}}${CleanVarName}{{[-]}} has not been changed, exit anyways?\n" "Save Variable" "${ASSUMEYES:+Y}" "Done" "Back"; then
							# Value has not changed, confirm exiting
							#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
							local -i PipeFD PipePID
							tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}Canceling Variable Edit" "${DialogHeading}" "${DIALOGTIMEOUT}"
							{
								if [[ -n ${APPNAME-} ]]; then
									if ! run_script 'app_is_user_defined' "${APPNAME}"; then
										run_script 'env_backup'
										run_script 'appvars_create' "${APPNAME}"
										run_script 'env_update'
										run_script 'env_sanitize'
									fi
								else
									run_script 'env_backup'
									run_script 'appvars_migrate_enabled_lines'
									run_script 'env_update'
									run_script 'env_sanitize'
								fi
							} >&${PipeFD} 2>&1 || true
							tui_pipe_close PipeFD PipePID
							return 0
						fi
					else
						if run_script 'question_prompt' --maximized N "${DialogHeading}\n\nWould you like to save {{|Highlight|}}${CleanVarName}{{[-]}}?\n" "Save Variable" "${ASSUMEYES:+Y}" "Save" "Back"; then
							# Value is valid, save it and exit
							#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
							local -i PipeFD PipePID
							tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}Saving Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
							{
								run_script 'env_set_literal' "${VarName}" "${OptionValue["${CurrentValueOption}"]}"
								if [[ -n ${APPNAME-} ]]; then
									if ! run_script 'app_is_user_defined' "${APPNAME}"; then
										run_script 'env_backup'
										run_script 'appvars_create' "${APPNAME}"
										run_script 'env_update'
										run_script 'env_sanitize'
									fi
								else
									run_script 'appvars_migrate_enabled_lines'
									run_script 'env_update'
									run_script 'env_sanitize'
								fi
							} >&${PipeFD} 2>&1 || true
							tui_pipe_close PipeFD PipePID
							return 0
						fi
					fi
				fi
				;;
			*)
				invalid_tui_button ${SelectValueDialogButtonPressed}
				;;
		esac
	done
}

menu_value_prompt_select_dialog() {
	dialog_inputmenu "$@"
}

menu_value_prompt_select_whiptail() {
	local Title="${1-}"
	shift || true
	local Message="${1-}"
	shift || true
	#shellcheck disable=SC2034 # (warning): ParsedOptions is passed by name to _whiptail_parse_options_ via nameref and appears unused to shellcheck.
	local -a ParsedOptions=()
	#shellcheck disable=SC2034 # (warning): Maximized is passed by name to _whiptail_parse_options_ via nameref and appears unused to shellcheck.
	local -i _n_=0 Maximized=0
	_whiptail_parse_options_ ParsedOptions Maximized _n_ "$@"
	shift "${_n_}"
	local -a Items=("$@")
	local -i OptionsLength=0
	local -i i
	for ((i = 0; i < ${#Items[@]}; i += 3)); do
		if [[ ${#Items[i]} -gt OptionsLength ]]; then
			OptionsLength=${#Items[i]}
		fi
	done
	local EnterCustom="<CUSTOM VALUE>"
	local CustomBar
	CustomBar=$(printf "%$(((OptionsLength - ${#EnterCustom}) / 2))s" '')
	EnterCustom="${CustomBar}${EnterCustom}${CustomBar}"
	Items+=("${EnterCustom}" "" "")
	local -a MenuDialog=(
		"${Title}"
		"${Message}"
		--maximized
		--item-help
		--ok-label:Select
		--cancel-label:Done
		"${Items[@]}"
	)
	local -i result=0
	local Selected
	Selected=$(tui_menu "${MenuDialog[@]}") || result=$?
	case ${DIALOG_BUTTONS[result]-} in
		OK)
			if [[ ${Selected} == "${EnterCustom}" ]]; then
				local NewValue
				NewValue=$(tui_inputbox "${Title}" "${Message}" --maximized) || result=$?
				case ${DIALOG_BUTTONS[result]-} in
					OK)
						echo "RENAMED Current Value ${NewValue}"
						return "${DIALOG_EXTRA}"
						;;
					*)
						return ${result}
						;;
				esac
			else
				echo "${Selected}"
				return "${DIALOG_OK}"
			fi
			;;
		*)
			return ${result}
			;;
	esac
}

menu_value_prompt_select() {
	if use_dialog; then
		menu_value_prompt_select_dialog "$@"
	else
		menu_value_prompt_select_whiptail "$@"
	fi
}

test_menu_value_prompt() {
	# run_script 'menu_value_prompt'
	warn "CI does not test menu_value_prompt."
}
