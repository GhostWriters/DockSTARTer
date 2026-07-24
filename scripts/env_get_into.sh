#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

env_get_into() {
	# env_get_into OutVar VarName [VarFile]
	# env_get_into OutVar APPNAME:VarName
	#
	# Returns the variable "VarName" If no "VarFile" is given, uses the global .env file
	# If "APPNAME:" is provided, gets variable from ".env.app.appname"
	local -n _egi_out_="${1}"
	assert_nameref_is_string "${1}"
	local _egi_VarName_=${2-}
	local _egi_VarFile_=${3:-$COMPOSE_ENV}

	if ! run_script 'varname_is_valid' "${_egi_VarName_}"; then
		error "{{[cyan]}}${_egi_VarName_}{{[-]}} is an invalid variable name."
		return
	fi

	if [[ ${_egi_VarName_} =~ ^[A-Za-z0-9_]+: ]]; then
		# VarName is in the form of "APPNAME:VARIABLE", set new file to use
		local _egi_APPNAME_=${_egi_VarName_%%:*}
		run_script 'app_env_file_into' _egi_VarFile_ "${_egi_APPNAME_}"
		_egi_VarName_=${_egi_VarName_#"${_egi_APPNAME_}:"}
	fi
	if [[ -e ${_egi_VarFile_} ]]; then
		local _egi_LiteralValue_
		run_script 'env_get_literal_into' _egi_LiteralValue_ "${_egi_VarName_}" "${_egi_VarFile_}"
		_egi_out_="$(${GREP} --color=never -Po "^\s*(?:(?:(?<Q>['\"]).*\k<Q>)|(?:[^\s]+(?:\s+(?!#)[^\s]+)*))" <<< "${_egi_LiteralValue_}" | xargs 2> /dev/null || true)"
	else
		# VarFile does not exist, give a warning
		warn "File '{{|File|}}${_egi_VarFile_}{{[-]}}' does not exist."
	fi
}

test_env_get_into() {
	# Return a "pass" for now.
	# There is an error to be fixed in "Var_15=  Va# lue# Not a Comment"
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	local -a Test=(
		Var_01 "Var_01='Value'" Value
		Var_02 "    Var_02='Value'" Value
		Var_03 "Var_03  ='Value'" Value
		Var_04 "    Var_04  ='Value'" Value
		Var_05 "Var_05=  'Value'" Value
		Var_06 "Var_06='Value'# Comment # kljkl" Value
		Var_07 "    Var_07='Value' # Comment" Value
		Var_08 "Var_08  ='Value' # Comment" Value
		Var_09 "    Var_09  ='Value' # Comment" Value
		Var_10 "Var_10=  'Value' # Comment" Value
		Var_11 "Var_11=  Value# Not a Comment" "Value# Not a Comment"
		Var_12 "Var_12=  '#Value' # Comment" "#Value"
		Var_13 "Var_13=  #Value# Not a Comment" "#Value# Not a Comment"
		Var_14 "Var_14=  'Va#lue' # Comment" "Va#lue"
		Var_15 "Var_15=  Va# lue# Not a Comment" "Va# lue# Not a Comment"
		Var_16 "Var_16=  Va# lue # Comment" "Va# lue"
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
			run_script 'env_get_into' Result "${Test[i]}" "${VarFile}"
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
