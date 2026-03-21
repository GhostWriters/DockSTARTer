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
		"Testing '{{|RunningCommand|}}${script_name}{{[-]}}'."
	[[ -f ${script_file} ]] ||
		fatal \
			"Script file '{{|File|}}${script_file}{{[-]}}' not found."

	# shellcheck source=/dev/null
	source "${script_file}"
	declare -F "${test_function}" &> /dev/null ||
		fatal \
			"Function '{{|RunningCommand|}}${test_function}{{[-]}}' not found in script file '{{|File|}}${script_file}{{[-]}}'."
	"${test_function}" "$@" ||
		fatal \
			"Test of '{{|FailingCommand|}}${script_name}{{[-]}}' failed."
	notice \
		"Completed testing '{{|RunningCommand|}}${script_name}{{[-]}}'."
}

run_unit_tests() {
	run_unit_tests_pipe "${1}" "${2}" "${3}" < <(
		printf '%s\n' "${@:4}"
	)
}
run_unit_tests_pipe() {
	local InputColor="{{|${1-Notice}}|}}"
	local ExpectedColor="{{|${2-Notice}}|}}"
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
	local FailLeft="{{|UnitTestFailArrow|}}>{{[-]}}"
	local FailRight="<{{|UnitTestFailArrow|}}{{[-]}}"
	local VisFailLeft
	VisFailLeft="$(strip_styles "${FailLeft}")"
	local VisFailRight
	VisFailRight="$(strip_styles "${FailRight}")"
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
		local ExpectedValue="${Test[i+1]-}"
		local ReturnedValue="${Test[i+2]-}"

		if [[ ${ReturnedValue} == "${ExpectedValue}" ]]; then
			LeftPointers+=("${LeftSpacer}")
			RightPointers+=("${RightSpacer}")
			TableData+=(
				"${InputColor}${Input}{{[-]}}"
				"${ExpectedColor}${ExpectedValue}{{[-]}}"
				"{{|UnitTestPass|}}${ReturnedValue}{{[-]}}"
			)
		else
			LeftPointers+=("{{|UnitTestFailArrow|}}>{{[-]}}")
			RightPointers+=("{{|UnitTestFailArrow|}}<{{[-]}}")
			TableData+=(
				"{{|UnitTestFail|}}${Input}{{[-]}}"
				"{{|UnitTestFail|}}${ExpectedValue}{{[-]}}"
				"{{|UnitTestFail|}}${ReturnedValue}{{[-]}}"
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
			if [[ ${result} != 0 && ${line} == *"{{|UnitTestFailArrow|}}>{{[-]}}"* ]]; then
				error "${line}"
			else
				notice "${line}"
			fi
		done

	if [[ -n ${ForcePass} ]]; then
		warn "The '{{|Var|}}ForcePass{{[-]}}' variable is set."
		if [[ ${result} != 0 ]]; then
			error \
				"Passing test even though an error occurred."
			return 0
		fi
	fi
	return ${result}
}
