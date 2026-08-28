#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

appvars_purge() {
	local Title="Purge Variables"
	local -a applist
	IFS=$' \t\n\r' read -d '' -ra applist <<< "${*,,}" || true
	for appname in "${applist[@]}"; do
		local AppName
		run_script 'app_nicename_into' AppName "${appname}"

		local -a CurrentGlobalVars DefaultGlobalVars GlobalVarsToRemove GlobalLinesToRemove
		local GlobalVarsRegex

		run_script 'appvars_list_into_array' CurrentGlobalVars "${appname}"
		if [[ -n ${CurrentGlobalVars-} ]]; then
			local AppDefaultGlobalEnvFile
			run_script 'app_instance_file_into' AppDefaultGlobalEnvFile "${appname}" ".env"
			run_script 'env_var_list_into_array' DefaultGlobalVars "${AppDefaultGlobalEnvFile}"
			# Get the list of current variables also in the default list
			readarray -t GlobalVarsToRemove <<< "$(
				printf '%s\n' "${CurrentGlobalVars[@]-}" "${DefaultGlobalVars[@]-}" |
					tr ' ' '\n' | sort | uniq -d || true
			)"
			{
				IFS='|'
				GlobalVarsRegex="${GlobalVarsToRemove[*]}"
			}
			readarray -t GlobalLinesToRemove <<< "$(${GREP} -P "^\s*${GlobalVarsRegex}\s*=" "${COMPOSE_ENV}" || true)"
		fi

		# A multi-service app can have more than one ".env.app.*" file --
		# appvars_filelist_into finds every one that currently exists on
		# disk (only existing files have anything to purge). A removal
		# plan is built for each, keyed by its own qualified name (e.g.
		# "immich-database"), and all shown together in one combined
		# confirmation prompt below.
		local -a AppFiles
		run_script 'appvars_filelist_into' AppFiles "${appname}"

		local -a AppFileQualifiedNames=()
		local -A AppEnvFileByName=()
		local -A AppEnvVarsRegexByName=()
		local -A AppEnvLinesToRemoveByName=()
		local AppFileName
		for AppFileName in "${AppFiles[@]}"; do
			local QualifiedAppName="${AppFileName#.env.app.}"
			local AppEnvFile
			run_script 'app_env_file_into' AppEnvFile "${QualifiedAppName}"

			local -a CurrentAppEnvVars DefaultAppEnvVars AppEnvVarsToRemove
			run_script 'appvars_list_into_array' CurrentAppEnvVars "${QualifiedAppName}:"
			[[ -n ${CurrentAppEnvVars-} ]] || continue

			local AppDefaultAppEnvFile
			local FileTemplate="${AppFileName/"${appname}"/\*}"
			run_script 'app_instance_file_into' AppDefaultAppEnvFile "${appname}" "${FileTemplate}"
			run_script 'env_var_list_into_array' DefaultAppEnvVars "${AppDefaultAppEnvFile}"
			readarray -t AppEnvVarsToRemove <<< "$(
				printf '%s\n' "${CurrentAppEnvVars[@]-}" "${DefaultAppEnvVars[@]-}" |
					tr ' ' '\n' | sort | uniq -d || true
			)"
			[[ -n ${AppEnvVarsToRemove[*]-} ]] || continue

			local AppEnvVarsRegex
			{
				IFS='|'
				AppEnvVarsRegex="${AppEnvVarsToRemove[*]}"
			}
			local -a AppEnvLinesToRemove
			readarray -t AppEnvLinesToRemove <<< "$(${GREP} -P "^\s*${AppEnvVarsRegex}\s*=" "${AppEnvFile}" || true)"
			[[ -n ${AppEnvLinesToRemove[*]-} ]] || continue

			AppFileQualifiedNames+=("${QualifiedAppName}")
			AppEnvFileByName["${QualifiedAppName}"]="${AppEnvFile}"
			AppEnvVarsRegexByName["${QualifiedAppName}"]="${AppEnvVarsRegex}"
			AppEnvLinesToRemoveByName["${QualifiedAppName}"]="$(printf '%s\n' "${AppEnvLinesToRemove[@]}")"
		done

		if [[ -z ${GlobalVarsToRemove[*]-} && -z ${AppFileQualifiedNames[*]-} ]]; then
			local WarningText="'{{|Highlight|}}{{|App|}}${AppName}{{[-]}}{{[-]}}' has no variables to remove."
			if use_tui_box; then
				tui_warning "${Title}" "${WarningText}"
				warn "${WarningText}" &> /dev/null
			else
				warn "${WarningText}"
			fi
			continue
		fi

		local Indent='   '
		local Question
		Question="Would you like to purge these settings for '{{|Highlight|}}{{|App|}}${AppName}{{[-]}}{{[-]}}'?\n"
		if [[ -n ${GlobalLinesToRemove[*]-} ]]; then
			Question+="${Indent}{{|Highlight|}}{{|Folder|}}${COMPOSE_ENV}{{[-]}}{{[-]}}:\n"
			for line in "${GlobalLinesToRemove[@]}"; do
				Question+="${Indent}${Indent}{{|Var|}}${line}{{[-]}}\n"
			done
		fi
		for QualifiedAppName in "${AppFileQualifiedNames[@]}"; do
			Question+="${Indent}{{|Highlight|}}{{|Folder|}}${AppEnvFileByName["${QualifiedAppName}"]}{{[-]}}{{[-]}}:\n"
			while IFS= read -r line; do
				[[ -n ${line} ]] || continue
				Question+="${Indent}${Indent}{{|Var|}}${line}{{[-]}}\n"
			done <<< "${AppEnvLinesToRemoveByName["${QualifiedAppName}"]}"
		done
		if [[ ${CI-} == true ]] || run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
			info "Purging '{{|App|}}${AppName}{{[-]}}' variables."

			if [[ -n ${GlobalVarsToRemove[*]-} ]]; then
				# Remove variables from global .env file
				notice \
					"Removing variables from {{|File|}}${COMPOSE_ENV}{{[-]}}:" \
					"$(printf "${Indent}{{|Var|}}%s{{[-]}}\n" "${GlobalLinesToRemove[@]}")"
				${SED} -i -E "/^\s*(${GlobalVarsRegex})\s*=/d" "${COMPOSE_ENV}" ||
					fatal \
						"Failed to purge '{{|App|}}${AppName}{{[-]}}' variables." \
						"Failing command: {{|FailingCommand|}}${SED} -i -E \"/^\\\*(${GlobalVarsRegex})\\\*/d\" \"${COMPOSE_ENV}\""
			fi
			for QualifiedAppName in "${AppFileQualifiedNames[@]}"; do
				local AppEnvFile="${AppEnvFileByName["${QualifiedAppName}"]}"
				local AppEnvVarsRegex="${AppEnvVarsRegexByName["${QualifiedAppName}"]}"
				# Remove variables from the .env.app.* file
				notice \
					"Removing variables from {{|File|}}${AppEnvFile}{{[-]}}:" \
					"$(printf "${Indent}{{|Var|}}%s{{[-]}}\n" "${AppEnvLinesToRemoveByName["${QualifiedAppName}"]}")"
				${SED} -i -E "/^\s*(${AppEnvVarsRegex})\s*=/d" "${AppEnvFile}" ||
					fatal \
						"Failed to purge '{{|App|}}${AppName}{{[-]}}' variables." \
						"Failing command: {{|FailingCommand|}}${SED} -i -E \"/^\\\*(${AppEnvVarsRegex})\\\*/d\" \"${AppEnvFile}\""
			done
		else
			info "Keeping '{{|App|}}${AppName}{{[-]}}' variables."
		fi
	done
	run_script 'unset_needs_appvars_create'
}

test_appvars_purge() {
	run_script 'appvars_purge' WATCHTOWER
	run_script 'env_update'
	echo "${COMPOSE_ENV}:"
	cat "${COMPOSE_ENV}"
	local EnvFile
	EnvFile="$(run_script 'app_env_file' "watchtower")"
	echo "${EnvFile}:"
	if [[ -f ${EnvFile} ]]; then
		cat "${EnvFile}"
	else
		echo "*File Not Found*"
	fi
}
