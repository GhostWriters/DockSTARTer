#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=()

env_get() {
	local result
	run_script 'env_get_into' result "$@"
	echo "${result}"
}

test_env_get() {
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
			printf '%s\n' \
				"${Test[i + 1]}" \
				"${Test[i + 2]}" \
				"$(run_script 'env_get' "${Test[i]}" "${VarFile}")"
		done
	)
	result=$?

	rm -f "${VarFile}" ||
		warn \
			"Failed to remove temporary file." \
			"Failing command: {{|FailingCommand|}}rm -f \"${VarFile}\""

	return ${result}
}
