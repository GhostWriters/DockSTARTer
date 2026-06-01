#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

env_format_lines() {
	local CurrentEnvFile=${1-}
	local DefaultEnvFile=${2-}
	local APPNAME=${3-}
	APPNAME=${APPNAME^^}

	local GlobalVarsHeading="Global Variables"
	local AppDeprecatedTag=" [*DEPRECATED*]"
	local AppDisabledTag=" (Disabled)"
	local AppUserDefinedTag=" (User Defined)"
	local UserDefinedVarsTag=" (User Defined Variables)"
	local UserDefinedGlobalVarsTag=" (User Defined)"

	local -a CurrentEnvLines=()
	run_script 'env_lines_into_array' CurrentEnvLines "${CurrentEnvFile}"

	local AppName=''
	local AppDescription=''
	local AppIsUserDefined=''
	local -a FormattedEnvLines=()
	if [[ -n ${APPNAME-} ]]; then
		# APPNAME is specified and added, output main app heading
		if run_script 'app_is_user_defined' "${APPNAME}"; then
			AppIsUserDefined='Y'
		fi
		run_script 'app_nicename_into' AppName "${APPNAME}"
		AppDescription="$(run_script 'app_description' "${APPNAME}" | wordwrap_pipe 75)"
		local HeadingTitle="${AppName}"
		if [[ ${AppIsUserDefined} == Y ]]; then
			HeadingTitle+="${AppUserDefinedTag}"
		else
			run_script 'app_is_deprecated' "${APPNAME}" && HeadingTitle+="${AppDeprecatedTag}"
			run_script 'app_is_disabled' "${APPNAME}" && HeadingTitle+="${AppDisabledTag}"
		fi

		local -a HeadingText=()
		HeadingText+=("")
		readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${HeadingTitle}")
		HeadingText+=("")
		readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${AppDescription}")
		HeadingText+=("")
		for line in "${HeadingText[@]}"; do
			local trimmed="${line%"${line##*[![:space:]]}"}"
			FormattedEnvLines+=("###${trimmed:+ ${trimmed}}")
		done
	fi
	if [[ -n ${DefaultEnvFile} && -f ${DefaultEnvFile} ]]; then
		# Default file is specified and exists, add the contents verbatim
		readarray -t -O ${#FormattedEnvLines[@]} FormattedEnvLines < "${DefaultEnvFile}"
		if [[ -n ${FormattedEnvLines[*]} ]]; then
			# Add a blank if there are existing lines (not at top of file)
			FormattedEnvLines+=("")
		fi
	fi

	# FormattedEnvVarIndex["VarName"]=index position of line in FormattedEnvLines
	local -A FormattedEnvVarIndex=()
	_build_var_index

	if [[ -n ${CurrentEnvLines[*]} ]]; then
		# Update the default variables
		for index in "${!CurrentEnvLines[@]}"; do
			local line=${CurrentEnvLines[index]}
			local VarName=${line%%=*}
			if [[ -n ${FormattedEnvVarIndex[$VarName]-} ]]; then
				# Variable already exists, update its value
				_update_line "${line}" "${VarName}"
				unset 'CurrentEnvLines[index]'
			fi
		done
		CurrentEnvLines=("${CurrentEnvLines[@]-}")
		if [[ -n ${CurrentEnvLines[*]} ]]; then
			if [[ -z ${APPNAME-} || ${AppIsUserDefined} != Y ]]; then
				# Add the "User Defined" heading
				local HeadingTitle
				if [[ -n ${AppName-} ]]; then
					HeadingTitle="${AppName}${UserDefinedVarsTag}"
				else
					HeadingTitle="${GlobalVarsHeading}${UserDefinedGlobalVarsTag}"
				fi
				local HeadingText=()
				HeadingText+=("")
				readarray -t -O ${#HeadingText[@]} HeadingText < <(printf '%b\n' "${HeadingTitle}")
				HeadingText+=("")
				for line in "${HeadingText[@]}"; do
					local trimmed="${line%"${line##*[![:space:]]}"}"
					FormattedEnvLines+=("###${trimmed:+ ${trimmed}}")
				done
			fi
			# Add the user defined variables
			for index in "${!CurrentEnvLines[@]}"; do
				local line=${CurrentEnvLines[index]}
				local VarName=${line%%=*}
				if [[ -n ${FormattedEnvVarIndex[$VarName]-} ]]; then
					# Variable already exists, update its value
					_update_line "${line}" "${VarName}"
				else
					# Variable is new, add it
					_add_line "${line}" "${VarName}"
				fi
			done
			FormattedEnvLines+=("")
		fi
	else
		FormattedEnvLines+=("")
	fi

	# Remove all trailing empty strings to avoid extra newlines from printf
	# This ensures parity with Go's strings.Join which doesn't add a trailing delimiter.
	while [[ ${#FormattedEnvLines[@]} -gt 0 && -z ${FormattedEnvLines[-1]-} ]]; do
		unset 'FormattedEnvLines[-1]'
	done

	if [[ ${#FormattedEnvLines[@]} -gt 0 ]]; then
		printf "%s\n" "${FormattedEnvLines[@]}"
	fi
}

_build_var_index() {
	FormattedEnvVarIndex=()
	local i line
	for i in "${!FormattedEnvLines[@]}"; do
		line="${FormattedEnvLines[${i}]}"
		if [[ ${line} =~ ^([A-Za-z0-9_]+)= ]]; then
			FormattedEnvVarIndex["${BASH_REMATCH[1]}"]="${i}"
		fi
	done
}

_update_line() {
	local line="${1}"
	local varname="${2:-${line%%=*}}"
	FormattedEnvLines[${FormattedEnvVarIndex[${varname}]}]="${line}"
}

_add_line() {
	local line="${1}"
	local varname="${2:-${line%%=*}}"
	FormattedEnvLines+=("${line}")
	FormattedEnvVarIndex["${varname}"]=$((${#FormattedEnvLines[@]} - 1))
}

test_env_format_lines() {
	#run_script 'env_format_lines' WATCHTOWER
	warn "CI does not test env_format_lines."
}
