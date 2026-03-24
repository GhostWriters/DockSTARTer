#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
	sed
)

appvars_purge() {
	local Title="Purge Variables"
	local -l applist
	applist="$(xargs -n 1 <<< "$*")"
	for appname in ${applist}; do
		local AppName
		AppName=$(run_script 'app_nicename' "${appname}")

		local AppEnvFile
		AppEnvFile="$(run_script 'app_env_file' "${appname}")"

		local -a CurrentGlobalVars DefaultGlobalVars GlobalVarsToRemove GlobalLinesToRemove
		local -a CurrentAppEnvVars DefaultAppEnvVars AppEnvVarsToRemove AppEnvLinesToRemove
		local GlobalVarsRegex AppEnvVarsRegex

		readarray -t CurrentGlobalVars <<< "$(run_script 'appvars_list' "${appname}")"
		if [[ -n ${CurrentGlobalVars-} ]]; then
			readarray -t DefaultGlobalVars <<< "$(run_script 'env_list_app_global_defaults' "${appname}")"
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

		readarray -t CurrentAppEnvVars <<< "$(run_script 'appvars_list' "${appname}:")"
		if [[ -n ${CurrentAppEnvVars-} ]]; then
			readarray -t DefaultAppEnvVars <<< "$(run_script 'env_list_app_env_defaults' "${appname}")"
			# Get the list of current variables also in the default list
			readarray -t AppEnvVarsToRemove <<< "$(
				printf '%s\n' "${CurrentAppEnvVars[@]-}" "${DefaultAppEnvVars[@]-}" |
					tr ' ' '\n' | sort | uniq -d || true
			)"
			{
				IFS='|'
				AppEnvVarsRegex="${AppEnvVarsToRemove[*]}"
			}
			readarray -t AppEnvLinesToRemove <<< "$(${GREP} -P "^\s*${AppEnvVarsRegex}\s*=" "${AppEnvFile}" || true)"
		fi

		if [[ -z ${GlobalVarsToRemove[*]-} && -z ${AppEnvVarsToRemove[*]-} ]]; then
			local WarningText="'{{|Highlight|}}{{|App|}}${AppName}{{[-]}}{{[-]}}' has no variables to remove."
			if use_dialog_box; then
				dialog_warning "${Title}" "${WarningText}"
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
		if [[ -n ${AppEnvLinesToRemove[*]-} ]]; then
			Question+="${Indent}{{|Highlight|}}{{|Folder|}}${AppEnvFile}{{[-]}}{{[-]}}:\n"
			for line in "${AppEnvLinesToRemove[@]}"; do
				Question+="${Indent}${Indent}{{|Var|}}${line}{{[-]}}\n"
			done
		fi
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
			if [[ -n ${AppEnvVarsToRemove[*]-} ]]; then
				# Remove variables from .env.app.appname file
				notice \
					"Removing variables from {{|File|}}${AppEnvFile}{{[-]}}:" \
					"$(printf "${Indent}{{|Var|}}%s{{[-]}}\n" "${AppEnvLinesToRemove[@]-}")"
				${SED} -i -E "/^\s*(${AppEnvVarsRegex})\s*=/d" "${AppEnvFile}" ||
					fatal \
						"Failed to purge '{{|App|}}${AppName}{{[-]}}' variables." \
						"Failing command: {{|FailingCommand|}}${SED} -i -E \"/^\\\*(${AppEnvVarsRegex})\\\*/d\" \"${AppEnvFile}\""
			fi
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
