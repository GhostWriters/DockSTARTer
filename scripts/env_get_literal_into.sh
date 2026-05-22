#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

env_get_literal_into() {
	# env_get_literal_into OutVar VarName [VarFile]
	# env_get_literal_into OutVar APPNAME:VarName
	#
	# The string returned will be the literal value after `=`, including quotes and comments
	#
	# Returns the variable "VarName" If no "VarFile" is given, uses the global .env file
	# If "APPNAME:" is provided, gets variable from ".env.app.appname"
	local -n _eglli_out_="${1}"
	local _eglli_VarName_=${2-}
	local _eglli_VarFile_=${3:-$COMPOSE_ENV}

	if ! run_script 'varname_is_valid' "${_eglli_VarName_}"; then
		error "'{{|Var|}}${_eglli_VarName_}{{[-]}}' is an invalid variable name."
		return
	fi

	if [[ ${_eglli_VarName_} =~ ^[A-Za-z0-9_]+: ]]; then
		# VarName is in the form of "APPNAME:VARIABLE", set new file to use
		local _eglli_APPNAME_=${_eglli_VarName_%%:*}
		run_script 'app_env_file_into' _eglli_VarFile_ "${_eglli_APPNAME_}"
		_eglli_VarName_=${_eglli_VarName_#"${_eglli_APPNAME_}:"}
	fi
	if [[ -e ${_eglli_VarFile_} ]]; then
		local _eglli_Line_
		run_script 'env_get_line_into' _eglli_Line_ "${_eglli_VarName_}" "${_eglli_VarFile_}"
		_eglli_out_="${_eglli_Line_#*=}"
	else
		# VarFile does not exist, give a warning
		warn "File '{{|File|}}${_eglli_VarFile_}{{[-]}}' does not exist."
	fi
}

test_env_get_literal_into() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	local -a Test=(
		Var_01 "Var_01='Value'" "'Value'"
		Var_02 "    Var_02='Value'" "'Value'"
		Var_03 "Var_03  ='Value'" "'Value'"
		Var_04 "    Var_04  ='Value'" "'Value'"
		Var_05 "Var_05=  'Value'" "  'Value'"
		Var_06 "Var_06='Value'# Comment # kljkl" "'Value'# Comment # kljkl"
		Var_07 "    Var_07='Value' # Comment" "'Value' # Comment"
		Var_08 "Var_08  ='Value' # Comment" "'Value' # Comment"
		Var_09 "    Var_09  ='Value' # Comment" "'Value' # Comment"
		Var_10 "Var_10=  'Value' # Comment" "  'Value' # Comment"
		Var_11 "Var_11=  Value# Not a Comment" "  Value# Not a Comment"
		Var_12 "Var_12=  '#Value' # Comment" "  '#Value' # Comment"
		Var_13 "Var_13=  #Value# Not a Comment" "  #Value# Not a Comment"
		Var_14 "Var_14=  'Va#lue' # Comment" "  'Va#lue' # Comment"
		Var_15 "Var_15=  Va# lue# Not a Comment" "  Va# lue# Not a Comment"
		Var_16 "Var_16=  Va# lue # Comment" "  Va# lue # Comment"
	)
	VarFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX") ||
		fatal \
			"Failed to create temporary file." \
			"Failing command: {{|FailingCommand|}}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX\""
	{
		printf '### %s\n' \
			"" \
			"${VarFile}" \
			""
		for ((i = 0; i < ${#Test[@]}; i += 3)); do
			printf '%s\n' "${Test[i + 1]}"
		done
	} > "${VarFile}"

	notice "$(cat "${VarFile}")"
	run_unit_tests_pipe "Var" "Var" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 3)); do
			local Result
			run_script 'env_get_literal_into' Result "${Test[i]}" "${VarFile}"
			printf '%s\n' \
				"${Test[i + 1]}" \
				"${Test[i + 2]}" \
				"${Result}"
		done
	)
	result=$?

	rm -f "${VarFile}" ||
		warn \
			"Failed to remove temporary file." \
			"Failing command: {{|FailingCommand|}}rm -f \"${VarFile}\""

	return ${result}
}
