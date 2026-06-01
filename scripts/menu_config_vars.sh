#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

menu_config_vars() {
	local APPNAME=${1-}
	APPNAME=${APPNAME^^}
	local appname=${APPNAME,,}

	local Title
	local AddVariableText='<ADD VARIABLE>'

	local CurrentGlobalEnvFile CurrentAppEnvFile DefaultGlobalEnvFile DefaultAppEnvFile

	local LastLineChoice=""
	while true; do
		if [[ -n ${CurrentGlobalEnvFile-} ]]; then
			RunAndLog "" "rm:info" \
				warn "Failed to remove temporary '{{|File|}}.env{{[-]}}' file." \
				rm -f "${CurrentGlobalEnvFile}"
		fi
		if [[ -n ${CurrentAppEnvFile-} ]]; then
			RunAndLog "" "rm:info" \
				warn "Failed to remove temporary '{{|File|}}.env.app.${appname}{{[-]}}' file." \
				rm -f "${CurrentAppEnvFile}"
		fi
		local DefaultGlobalEnvFile=''
		local DefaultAppEnvFile=''
		if [[ -n ${APPNAME-} ]]; then
			Title="Edit Application Variables"
			CurrentGlobalEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentGlobalEnvFile.XXXXXXXXXX")
			CurrentAppEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentAppEnvFile.XXXXXXXXXX")
			if ! run_script 'app_is_user_defined' "${APPNAME}"; then
				run_script 'app_instance_file_into' DefaultGlobalEnvFile "${APPNAME}" ".env"
				run_script 'app_instance_file_into' DefaultAppEnvFile "${APPNAME}" ".env.app.*"
			fi
		else
			Title="Edit Global Variables"
			CurrentGlobalEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentGlobalEnvFile.XXXXXXXXXX")
			DefaultGlobalEnvFile="${COMPOSE_ENV_DEFAULT_FILE}"
		fi
		local -a LineOptions=()
		local -a VarNameOnLine=()
		local -a CurrentValueOnLine=()
		local -a LineColor=()
		local -i LineNumber=0
		local FirstVarLine

		# Add lines from global .env file to the dialog
		if [[ -n ${APPNAME-} ]]; then
			LineNumber+=1
			LineColor[LineNumber]="{{|LineHeading|}}"
			CurrentValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
		fi
		run_script 'appvars_lines' "${APPNAME}" > "${CurrentGlobalEnvFile}"
		local -a CurrentGlobalEnvLines
		run_script 'env_format_lines_into_array' CurrentGlobalEnvLines "${CurrentGlobalEnvFile}" "${DefaultGlobalEnvFile}" "${APPNAME}"
		for line in "${CurrentGlobalEnvLines[@]-}"; do
			LineNumber+=1
			CurrentValueOnLine[LineNumber]="${line}"
			local VarName=""
			[[ ${line} =~ ^([[:alnum:]_]+) ]] && VarName="${BASH_REMATCH[1]}"
			if [[ -n ${VarName-} ]]; then
				# Line contains a variable
				local DefaultLine DefaultVal
				run_script 'var_default_value_into' DefaultVal "${VarName}"
				DefaultLine="${VarName}=${DefaultVal}"
				if [[ ${line} == "${DefaultLine}" ]]; then
					LineColor[LineNumber]="{{|LineVar|}}"
				else
					LineColor[LineNumber]="{{|ModifiedText|}}"
				fi
				VarNameOnLine[LineNumber]="${VarName}"
				if [[ -z ${FirstVarLine-} ]]; then
					FirstVarLine=${LineNumber}
				fi
			elif [[ ${line} =~ ^[[:space:]]*# ]]; then
				# Line is a comment
				LineColor[LineNumber]="{{|LineComment|}}"
			else
				# Line is an unknowwn line
				LineColor[LineNumber]="{{|LineAddVariable|}}"
			fi
		done
		LineNumber+=1
		local AddGlobalVariableLineNumber=${LineNumber}
		CurrentValueOnLine[LineNumber]="${AddVariableText}"
		LineColor[LineNumber]="{{|LineAddVariable|}}"

		if [[ -n ${APPNAME-} ]]; then
			# Add lines from appvar.env file to the dialog
			LineNumber+=1
			CurrentValueOnLine[LineNumber]=""
			LineColor[LineNumber]="{{|LineOther|}}"
			LineNumber+=1
			local AppEnvFilePath
			run_script 'app_env_file_into' AppEnvFilePath "${APPNAME}"
			CurrentValueOnLine[LineNumber]="*** ${AppEnvFilePath} ***"
			LineColor[LineNumber]="{{|LineHeading|}}"
			run_script 'appvars_lines' "${APPNAME}:" > "${CurrentAppEnvFile}"
			local -a CurrentAppEnvLines
			run_script 'env_format_lines_into_array' CurrentAppEnvLines "${CurrentAppEnvFile}" "${DefaultAppEnvFile}" "${APPNAME}"
			for line in "${CurrentAppEnvLines[@]}"; do
				LineNumber+=1
				CurrentValueOnLine[LineNumber]="${line}"
				local VarName=""
				[[ ${line} =~ ^([[:alnum:]_]+) ]] && VarName="${BASH_REMATCH[1]}"
				if [[ -n ${VarName-} ]]; then
					# Line contains a variable
					local DefaultLine DefaultVal
					run_script 'var_default_value_into' DefaultVal "${APPNAME}:${VarName}"
					DefaultLine="${VarName}=${DefaultVal}"
					if [[ ${line} == "${DefaultLine}" ]]; then
						LineColor[LineNumber]="{{|LineVar|}}"
					else
						LineColor[LineNumber]="{{|ModifiedText|}}"
					fi
					VarNameOnLine[LineNumber]="${APPNAME}:${VarName}"
					if [[ -z ${FirstVarLine-} ]]; then
						FirstVarLine=${LineNumber}
					fi
				elif [[ ${line} =~ ^[[:space:]]*# ]]; then
					# Line is a comment
					LineColor[LineNumber]="{{|LineComment|}}"
				else
					# Line is an unknowwn line
					LineColor[LineNumber]="{{|LineOther|}}"
				fi
			done
			LineNumber+=1
			local AddAppEnvVariableLineNumber=${LineNumber}
			CurrentValueOnLine[LineNumber]="${AddVariableText}"
			LineColor[LineNumber]="{{|LineAddVariable|}}"
		fi

		local TotalLines=$((10#${LineNumber}))
		local PadSize=${#TotalLines}
		for LineNumber in "${!CurrentValueOnLine[@]}"; do
			local PaddedLineNumber=""
			PaddedLineNumber="$(printf "%0${PadSize}d" "${LineNumber}")"
			local HelpLine=""
			if [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
				run_script 'var_helpline_into' HelpLine "${VarNameOnLine[LineNumber]}"
			fi
			LineOptions+=("${PaddedLineNumber}" "${LineColor[LineNumber]-}${CurrentValueOnLine[LineNumber]}" "${HelpLine}")
		done
		if [[ -z ${LastLineChoice-} ]]; then
			# Set the default line to the first line with a variable on it
			LastLineChoice="$(printf "%0${PadSize}d" "${FirstVarLine}")"
		elif [[ $((10#${LastLineChoice})) -gt ${TotalLines} ]]; then
			LastLineChoice="$(printf "%0${PadSize}d" "${TotalLines}")"
		fi
		while true; do
			local DialogHeading LineChoice=""
			run_script 'menu_heading_into' DialogHeading "${APPNAME-}"
			local -a LineDialog=(
				"${Title}"
				"${DialogHeading}"
				--maximized
				--ok-label:Select
				--extra-label:Remove
				--cancel-label:Back
				--default-item:"${LastLineChoice}"
				--item-help
				"${LineOptions[@]}"
			)
			local -i LineDialogButtonPressed=0
			tui_menu_into LineChoice "${LineDialog[@]}" || LineDialogButtonPressed=$?
			case ${DIALOG_BUTTONS[LineDialogButtonPressed]-} in
				OK) # Select
					LastLineChoice="${LineChoice}"
					local LineNumber
					LineNumber=$((10#${LineChoice}))
					if [[ ${LineNumber} == "${AddGlobalVariableLineNumber-}" ]]; then
						run_script 'menu_add_var' "${APPNAME}"
						break
					elif [[ ${LineNumber} == "${AddAppEnvVariableLineNumber-}" ]]; then
						run_script 'menu_add_var' "${APPNAME}:"
						break
					elif [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
						run_script 'menu_value_prompt' "${VarNameOnLine[LineNumber]}"
						break
					fi
					;;
				EXTRA) # Remove
					LastLineChoice="${LineChoice}"
					local LineNumber
					LineNumber=$((10#${LineChoice}))
					local VarName="${VarNameOnLine[LineNumber]-}"
					if [[ -n ${VarName} ]]; then
						local DialogHeading
						run_script 'menu_heading_into' DialogHeading "${APPNAME-}" "${VarName}"
						local CleanVarName="${VarName}"
						if [[ ${CleanVarName} == *":"* ]]; then
							CleanVarName="${CleanVarName#*:}"
						fi
						local Question="Do you really want to delete {{|Highlight|}}${CleanVarName}{{[-]}}?"
						if run_script 'question_prompt' N "${DialogHeading}\n\n${Question}\n" "Delete Variable" "${ASSUMEYES:+Y}" "Delete" "Back"; then
							run_script 'menu_heading_into' DialogHeading "${APPNAME-}" "${VarName}"
							#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
							local -i PipeFD PipePID
							tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}Deleting Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
							{
								run_script 'env_delete' "${VarName}"
								if [[ -n ${APPNAME-} ]]; then
									if ! run_script 'app_is_user_defined' "${APPNAME}"; then
										run_script 'env_backup'
										run_script 'appvars_migrate' "${APPNAME}"
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
							} >&${PipeFD} 2>&1
							tui_pipe_close PipeFD PipePID
							break
						fi
					fi
					;;
				CANCEL | ESC) # Back
					return
					;;
				*)
					invalid_tui_button ${LineDialogButtonPressed}
					;;
			esac
		done
	done
	if [[ -n ${CurrentGlobalEnvFile-} ]]; then
		RunAndLog "" "rm:info" \
			warn "Failed to remove temporary '{{|File|}}.env{{[-]}}' file." \
			rm -f "${CurrentGlobalEnvFile}"
	fi
	if [[ -n ${CurrentAppEnvFile-} ]]; then
		RunAndLog "" "rm:info" \
			warn "Failed to remove temporary '{{|File|}}.env.app.${appname}{{[-]}}' file." \
			rm -f "${CurrentAppEnvFile}"
	fi
}

test_menu_config_vars() {
	# run_script 'menu_config_vars'
	warn "CI does not test menu_config_vars."
}
