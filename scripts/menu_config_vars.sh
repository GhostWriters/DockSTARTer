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

	local CurrentGlobalEnvFile DefaultGlobalEnvFile
	local -a CurrentAppEnvFiles=()

	local LastLineChoice=""
	while true; do
		if [[ -n ${CurrentGlobalEnvFile-} ]]; then
			RunAndLog "" "rm:info" \
				warn "Failed to remove temporary '{{|File|}}.env{{[-]}}' file." \
				rm -f "${CurrentGlobalEnvFile}"
		fi
		local TempFile
		for TempFile in "${CurrentAppEnvFiles[@]-}"; do
			[[ -n ${TempFile} ]] || continue
			RunAndLog "" "rm:info" \
				warn "Failed to remove temporary app env file." \
				rm -f "${TempFile}"
		done
		CurrentAppEnvFiles=()
		local DefaultGlobalEnvFile=''
		local IsUserDefined=''
		if [[ -n ${APPNAME-} ]]; then
			Title="Edit Application Variables"
			CurrentGlobalEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentGlobalEnvFile.XXXXXXXXXX")
			if run_script 'app_is_user_defined' "${APPNAME}"; then
				IsUserDefined='Y'
			else
				run_script 'app_instance_file_into' DefaultGlobalEnvFile "${APPNAME}" ".env"
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
			# A multi-service app ships more than one ".env.app.*" file
			# (the plain one, any real per-service "___service" file, any
			# shared/virtual "-suffix" file) -- one section per file below,
			# same as DockSTARTer2's tabbed editor. Built-in apps use the
			# template-defined set (apptemplate_filelist_into -- guaranteed
			# to already exist as real files by the time this editor opens,
			# since appvars_create touches all of them into existence);
			# user-defined apps have no template, so fall back to whatever
			# files actually exist on disk (appvars_filelist_into).
			local -a AppFileTemplates=()
			if [[ ${IsUserDefined} != Y ]]; then
				run_script 'apptemplate_filelist_into' AppFileTemplates "${appname}"
			fi
			if [[ -z ${AppFileTemplates[*]-} ]]; then
				local -a ExistingAppFiles
				run_script 'appvars_filelist_into' ExistingAppFiles "${appname}"
				local ExistingFile
				for ExistingFile in "${ExistingAppFiles[@]-}"; do
					AppFileTemplates+=("${ExistingFile/"${appname}"/\*}")
				done
			fi
			if [[ -z ${AppFileTemplates[*]-} ]]; then
				AppFileTemplates=(".env.app.*")
			fi

			# AddAppEnvVariableLineNumberFor[N]=1 marks LineNumber N as the
			# "add variable" row for section index N's file/app-name below.
			local -A AddAppEnvVariableLineNumberFor=()
			local -a QualifiedAppNameForSection=()
			local -i SectionIndex=0
			local FileTemplate
			for FileTemplate in "${AppFileTemplates[@]}"; do
				local QualifiedAppName="${FileTemplate//"*"/"${appname}"}"
				QualifiedAppName="${QualifiedAppName#.env.app.}"
				QualifiedAppNameForSection[SectionIndex]="${QualifiedAppName}"

				local DefaultAppEnvFile=''
				if [[ ${IsUserDefined} != Y ]]; then
					run_script 'app_instance_file_into' DefaultAppEnvFile "${APPNAME}" "${FileTemplate}"
				fi

				LineNumber+=1
				CurrentValueOnLine[LineNumber]=""
				LineColor[LineNumber]="{{|LineOther|}}"
				LineNumber+=1
				local AppEnvFilePath
				run_script 'app_env_file_into' AppEnvFilePath "${QualifiedAppName}"
				CurrentValueOnLine[LineNumber]="*** ${AppEnvFilePath} ***"
				LineColor[LineNumber]="{{|LineHeading|}}"

				local CurrentAppEnvFile
				CurrentAppEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentAppEnvFile.XXXXXXXXXX")
				CurrentAppEnvFiles+=("${CurrentAppEnvFile}")
				run_script 'appvars_lines' "${QualifiedAppName}:" > "${CurrentAppEnvFile}"
				local -a CurrentAppEnvLines
				run_script 'env_format_lines_into_array' CurrentAppEnvLines "${CurrentAppEnvFile}" "${DefaultAppEnvFile}" "${APPNAME}" "$(basename "${AppEnvFilePath}")"
				for line in "${CurrentAppEnvLines[@]}"; do
					LineNumber+=1
					CurrentValueOnLine[LineNumber]="${line}"
					local VarName=""
					[[ ${line} =~ ^([[:alnum:]_]+) ]] && VarName="${BASH_REMATCH[1]}"
					if [[ -n ${VarName-} ]]; then
						# Line contains a variable
						local DefaultLine DefaultVal
						run_script 'var_default_value_into' DefaultVal "${QualifiedAppName}:${VarName}"
						DefaultLine="${VarName}=${DefaultVal}"
						if [[ ${line} == "${DefaultLine}" ]]; then
							LineColor[LineNumber]="{{|LineVar|}}"
						else
							LineColor[LineNumber]="{{|ModifiedText|}}"
						fi
						VarNameOnLine[LineNumber]="${QualifiedAppName}:${VarName}"
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
				CurrentValueOnLine[LineNumber]="${AddVariableText}"
				LineColor[LineNumber]="{{|LineAddVariable|}}"
				AddAppEnvVariableLineNumberFor[${LineNumber}]="${SectionIndex}"

				SectionIndex+=1
			done
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
					elif [[ -n ${AddAppEnvVariableLineNumberFor[${LineNumber}]-} ]]; then
						local -i SectionIndex="${AddAppEnvVariableLineNumberFor[${LineNumber}]}"
						run_script 'menu_add_var' "${QualifiedAppNameForSection[SectionIndex]}:"
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
	local TempFile
	for TempFile in "${CurrentAppEnvFiles[@]-}"; do
		[[ -n ${TempFile} ]] || continue
		RunAndLog "" "rm:info" \
			warn "Failed to remove temporary app env file." \
			rm -f "${TempFile}"
	done
}

test_menu_config_vars() {
	# run_script 'menu_config_vars'
	warn "CI does not test menu_config_vars."
}
