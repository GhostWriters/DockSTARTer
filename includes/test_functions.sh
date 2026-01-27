#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Test Runner Function
run_test() {
	local script_name=${1-}
	shift

	local function_prefix="test_"
	local script_file="${SCRIPTPATH}/scripts/${script_name}.sh"
	local test_function="${function_prefix}${script_name}"

	notice \
		"Testing '${C["RunningCommand"]-}${script_name}${NC-}'."
	[[ -f ${script_file} ]] ||
		fatal \
			"Script file '${C["File"]-}${script_file}${NC-}' not found."

	# shellcheck source=/dev/null
	source "${script_file}"
	declare -F "${test_function}" &> /dev/null ||
		fatal \
			"Function '${C["RunningCommand"]-}${test_function}${NC-}' not found in script file '${C["File"]-}${script_file}${NC-}'."
	"${test_function}" "$@" ||
		fatal \
			"Test of '${C["FailingCommand"]-}${script_name}${NC-}' failed."
	notice \
		"Completed testing '${C["RunningCommand"]-}${script_name}${NC-}'."
}

run_unit_tests() {
	run_unit_tests_pipe "${1}" "${2}" "${3}" < <(
		printf '%s\n' "${@:4}"
	)
}
run_unit_tests_pipe() {
	local InputColor="${C["${1-Notice}"]-}"
	local ExpectedColor="${C["${2-Notice}"]-}"
	local ForcePass=${3-}
	local -a Test
	readarray -t Test

	local -i result=0
	local -a Headings=(
		"Input" "Expected Value" "Returned Value"
	)

	local -a TableData
	local -a LeftPointers
	local -a RightPointers

	# Calculate Padding
	local FailLeft="${C["UnitTestFailArrow"]-}>"
	local FailRight="<${C["UnitTestFailArrow"]-}"
	local VisFailLeft
	VisFailLeft="$(strip_ansi_colors "${FailLeft}")"
	local VisFailRight
	VisFailRight="$(strip_ansi_colors "${FailRight}")"
	local -i LeftPadSize=${#VisFailLeft}
	local -i RightPadSize=${#VisFailRight}
	local LeftSpacer
	LeftSpacer="$(printf "%*s" "${LeftPadSize}" "")"
	local RightSpacer
	RightSpacer="$(printf "%*s" "${RightPadSize}" "")"

	# Padding for Top Border, Header, Middle Border
	LeftPointers+=("${LeftSpacer}" "${LeftSpacer}" "${LeftSpacer}")
	RightPointers+=("${RightSpacer}" "${RightSpacer}" "${RightSpacer}")

	local -i i
	for ((i = 0; i < ${#Test[@]}; i += 3)); do
		local Input="${Test[i]-}"
		local ExpectedValue="${Test[i + 1]-}"
		local ReturnedValue="${Test[i + 2]-}"

		if [[ ${ReturnedValue} == "${ExpectedValue}" ]]; then
			LeftPointers+=("${LeftSpacer}")
			RightPointers+=("${RightSpacer}")
			TableData+=(
				"${InputColor}${Input}${NC-}"
				"${ExpectedColor}${ExpectedValue}${NC-}"
				"${C["UnitTestPass"]-}${ReturnedValue}${NC-}"
			)
		else
			LeftPointers+=("${C["UnitTestFailArrow"]-}>${NC-}")
			RightPointers+=("${C["UnitTestFailArrow"]-}<${NC-}")
			TableData+=(
				"${C["UnitTestFail"]-}${Input}${NC-}"
				"${C["UnitTestFail"]-}${ExpectedValue}${NC-}"
				"${C["UnitTestFail"]-}${ReturnedValue}${NC-}"
			)
			result=1
		fi
	done

	# Padding for Bottom Border
	LeftPointers+=("${LeftSpacer}")
	RightPointers+=("${RightSpacer}")

	# Paste pointers and table together
	paste -d '' \
		<(printf '%s\n' "${LeftPointers[@]}") \
		<(printf '%s\n' "${TableData[@]}" | table_pipe 3 "${Headings[@]}") \
		<(printf '%s\n' "${RightPointers[@]}") |
		while IFS= read -r line; do
			if [[ ${result} != 0 && ${line} == *"${C["UnitTestFailArrow"]-}>${NC-}"* ]]; then
				error "${line}"
			else
				notice "${line}"
			fi
		done

	if [[ -n ${ForcePass} ]]; then
		warn "The '${C["Var"]-}ForcePass${NC-}' variable is set."
		if [[ ${result} != 0 ]]; then
			error \
				"Passing test even though an error occurred."
			return 0
		fi
	fi
	return ${result}
}
