#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	grep
)

expand_vars_using_varfile() {
	local String="${1-}"
	local SkipVarName="${2-}"
	local VarFile="${3:-$COMPOSE_ENV}"
	if [[ $# -ge 3 ]]; then
		shift 3
	else
		shift $#
	fi

	local -A Vars
	while [[ $# -ge 2 ]]; do
		Vars["$1"]="$2"
		shift 2
	done

	local -A MissingVars

	local Changed=1
	local -i LoopCount=0
	local -i MaxLoops=10

	while [[ ${Changed} -eq 1 && ${LoopCount} -lt ${MaxLoops} ]]; do
		Changed=0

		# Find all variable inclusions in the string (deduplicate using associative array)
		local -A FoundVars=()
		# shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
		while IFS= read -r FoundVar; do
			[[ -n ${FoundVar} ]] && FoundVars["${FoundVar}"]=1
		done < <(echo "${String}" | ${GREP} -oP '(\$\{\K[a-zA-Z0-9_]+(?=(\?|-)?}))|(\$(?!\{)\K[a-zA-Z0-9_]+)' || true)

		# Sort keys by length descending to prevent partial matches (e.g. $VAR matching start of $VAR_LONG)
		local -a OrderedVars=()
		while IFS= read -r VarName; do
			OrderedVars+=("${VarName}")
		done < <(
			for Key in "${!FoundVars[@]}"; do
				echo "${#Key} ${Key}"
			done | sort -rn | cut -d" " -f2-
		)

		for Key in "${OrderedVars[@]}"; do
			if [[ -n ${SkipVarName} && ${Key} == "${SkipVarName}" ]]; then
				continue
			fi

			# If we generally checked this already (found or missing), skip
			if [[ -n ${Vars[${Key}]+x} || -n ${MissingVars[${Key}]+x} ]]; then
				continue
			fi

			# Look for the variable in the file
			if run_script 'env_var_exists' "${Key}" "${VarFile}"; then
				Vars["${Key}"]="$(run_script 'env_get' "${Key}" "${VarFile}")"
			else
				MissingVars["${Key}"]=1
			fi
		done

		for Key in "${OrderedVars[@]}"; do
			# Only attempt replacement if we found a value for this key
			if [[ -n ${Vars[${Key}]+x} ]]; then
				if [[ ${String} == *"\${${Key}?}"* ]]; then
					local NewString="${String//\$\{${Key}\?\}/${Vars[${Key}]}}"
					if [[ ${NewString} != "${String}" ]]; then
						String="${NewString}"
						Changed=1
					fi
				fi
				if [[ ${String} == *"\${${Key}-}"* ]]; then
					local NewString="${String//\$\{${Key}-\}/${Vars[${Key}]}}"
					if [[ ${NewString} != "${String}" ]]; then
						String="${NewString}"
						Changed=1
					fi
				fi
				if [[ ${String} == *"\${${Key}}"* ]]; then
					local NewString="${String//\$\{${Key}\}/${Vars[${Key}]}}"
					if [[ ${NewString} != "${String}" ]]; then
						String="${NewString}"
						Changed=1
					fi
				fi
				if [[ ${String} == *"\$${Key}"* ]]; then
					local NewString="${String//\$${Key}/${Vars[${Key}]}}"
					if [[ ${NewString} != "${String}" ]]; then
						String="${NewString}"
						Changed=1
					fi
				fi
			elif [[ -n ${MissingVars[${Key}]+x} ]]; then
				if [[ ${String} == *"\${${Key}?}"* ]]; then
					fatal "Variable '${C["Var"]-}${Key}${NC-}' is required but not defined."
				fi
			fi
		done
		LoopCount+=1
	done
	echo "${String}"
}

test_expand_vars_using_varfile() {
	local ForcePass='' # Force the tests to pass even on failure if set to a non-empty value
	local -i result=0

	# Define variables for the file
	# shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
	local VarFileContent="SIMPLE='SimpleValue'
RECURSIVE_A='\${RECURSIVE_B}'
RECURSIVE_B='RecursiveValue'
PARTIAL_A='Part'
PARTIAL_B='ial'
Mixed='\${SIMPLE} text'
SHORT='ShortValue'
SHORT_LONG='LongValue'
"

	# shellcheck disable=SC2016 # Expressions don't expand in single quotes, use double quotes for that.
	local -a Test=(
		# TestName      InputString                     SkipVarName     ExpectedOutput
		Simple '${SIMPLE}' '' 'SimpleValue'
		Recursive '${RECURSIVE_A}' '' 'RecursiveValue'
		Combined '${PARTIAL_A}${PARTIAL_B}' '' 'Partial'
		Unknown '${UNKNOWN}' '' '${UNKNOWN}'
		Skip '${SIMPLE}' 'SIMPLE' '${SIMPLE}'
		Skip_Other '${SIMPLE}' 'OTHER' 'SimpleValue'
		Mixed 'Start ${Mixed} End' 'Mixed' 'Start ${Mixed} End'
		Mixed_Recurse 'Start ${Mixed} End' '' 'Start SimpleValue text End'
		NoBrace '$SIMPLE' '' 'SimpleValue'
		NoBrace_Mix '$SIMPLE and ${SIMPLE}' '' 'SimpleValue and SimpleValue'
		Partial_Safe '$SHORT and $SHORT_LONG' '' 'ShortValue and LongValue'
		Partial_Safe_Rev '$SHORT_LONG and $SHORT' '' 'LongValue and ShortValue'
		DashSyntax '${SIMPLE-}' '' 'SimpleValue'
	)

	local VarFile
	VarFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX") ||
		fatal \
			"Failed to create temporary file." \
			"Failing command: ${C["FailingCommand"]-}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX\""
	echo "${VarFileContent}" > "${VarFile}"

	notice \
		"Contents of file '${C["File"]-}${VarFile}${NC-}':" \
		"${VarFileContent}"
	notice \
		""

	run_unit_tests_pipe "Input" "Input" "${ForcePass}" < <(
		for ((i = 0; i < ${#Test[@]}; i += 4)); do
			printf '%s\n' \
				"String='${Test[i + 1]}' Skip='${Test[i + 2]}'" \
				"${Test[i + 3]}" \
				"$(run_script 'expand_vars_using_varfile' "${Test[i + 1]}" "${Test[i + 2]}" "${VarFile}")"
		done
	)
	result=$?

	rm -f "${VarFile}" ||
		warn \
			"Failed to remove temporary file." \
			"Failing command: ${C["FailingCommand"]-}rm -f \"${VarFile}\""

	return ${result}
}
