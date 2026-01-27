#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

env_get_line() {
	# env_get_line VarName [VarFile]
	# env_get_line APPNAME:VarName
	#
	# Returns the variable "VarName"  If no "VarFile" is given, uses the global .env file
	# If "APPNAME:" is provided, gets variable from ".env.app.appname"
	local VarName=${1-}
	local VarFile=${2:-$COMPOSE_ENV}

	if ! run_script 'varname_is_valid' "${VarName}"; then
		error "'${C["Var"]}${VarName}${NC}' is an invalid variable name."
		return
	fi

	if [[ ${VarName} =~ ^[A-Za-z0-9_]+: ]]; then
		# VarName is in the form of "APPNAME:VARIABLE", set new file to use
		local APPNAME=${VarName%%:*}
		VarFile="$(run_script 'app_env_file' "${APPNAME}")"
		VarName=${VarName#"${APPNAME}:"}
	fi
	if [[ -e ${VarFile} ]]; then
		${GREP} --color=never -Po "^\s*${VarName}\s*=.*" "${VarFile}" | tail -1 || true
	else
		# VarFile does not exist, give a warning
		warn "File '${C["File"]}${VarFile}${NC}' does not exist."
	fi

}

test_env_get_line() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0
	local -a Test=(
		Var_01 "Var_01='Value'" "Var_01='Value'"
		Var_02 "    Var_02='Value'" "    Var_02='Value'"
		Var_03 "Var_03  ='Value'" "Var_03  ='Value'"
		Var_04 "    Var_04  ='Value'" "    Var_04  ='Value'"
		Var_05 "Var_05=  'Value'" "Var_05=  'Value'"
		Var_06 "Var_06='Value'# Comment # kljkl" "Var_06='Value'# Comment # kljkl"
		Var_07 "    Var_07='Value' # Comment" "    Var_07='Value' # Comment"
		Var_08 "Var_08  ='Value' # Comment" "Var_08  ='Value' # Comment"
		Var_09 "    Var_09  ='Value' # Comment" "    Var_09  ='Value' # Comment"
		Var_10 "Var_10=  'Value' # Comment" "Var_10=  'Value' # Comment"
		Var_11 "Var_11=  Value# Not a Comment" "Var_11=  Value# Not a Comment"
		Var_12 "Var_12=  '#Value' # Comment" "Var_12=  '#Value' # Comment"
		Var_13 "Var_13=  #Value# Not a Comment" "Var_13=  #Value# Not a Comment"
		Var_14 "Var_14=  'Va#lue' # Comment" "Var_14=  'Va#lue' # Comment"
		Var_15 "Var_15=  Va# lue# Not a Comment" "Var_15=  Va# lue# Not a Comment"
		Var_16 "Var_16=  Va# lue # Comment" "Var_16=  Va# lue # Comment"
	)
	VarFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX") ||
		fatal \
			"Failed to create temporary file." \
			"Failing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX\""
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
				"$(run_script 'env_get_line' "${Test[i]}" "${VarFile}")"
		done
	)
	result=$?

	rm -f "${VarFile}" ||
		warn \
			"Failed to remove temporary file." \
			"Failing command: ${C["FailingCommand"]}rm -f \"${VarFile}\""

	return ${result}
}
