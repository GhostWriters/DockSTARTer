#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Test Runner Function
run_test() {
    local script_name=${1-}
    shift

    local function_prefix="test_"
    local script_file="${SCRIPTPATH}/.scripts/${script_name}.sh"
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

    local -i InputCols ExpectedValueCols ReturnedValueCols
    {
        read -r InputCols
        read -r ExpectedValueCols
        read -r ReturnedValueCols
    } < <(longest_columns 3 "${Headings[@]}" "${Test[@]}")
    local Input="${Headings[0]}"
    local ExpectedValue="${Headings[1]}"
    local ReturnedValue="${Headings[2]}"

    local -i InputPadSize ExpectedValuePadSize ReturnedValuePadSize
    InputPadSize=$((InputCols - ${#Input}))
    ExpectedValuePadSize=$((ExpectedValueCols - ${#ExpectedValue}))
    ReturnedValuePadSize=$((ReturnedValueCols - ${#ReturnedValue}))

    local InputPad ExpectedValuePad ReturnedValuePad
    InputPad="$(printf "%*s" ${InputPadSize})"
    ExpectedValuePad="$(printf "%*s" ${ExpectedValuePadSize})"
    ReturnedValuePad="$(printf "%*s" ${ReturnedValuePadSize})"
    local TableLine
    TableLine="$(
        printf "+ %*s   + %*s   +   %*s +" \
            "${InputCols}" "" "${ExpectedValueCols}" "" "${ReturnedValueCols}" ""
    )"
    TableLine=" ${TableLine// /-} "
    local Heading
    Heading="$(
        printf " | %s  ${InputPad} | %s  ${ExpectedValuePad} | %s  ${ReturnedValuePad} | " \
            "${Headings[0]}" "${Headings[1]}" "${Headings[2]}"
    )"
    notice \
        "${TableLine}" \
        "${Heading}" \
        "${TableLine}"
    local -i i
    for ((i = 0; i < ${#Test[@]}; i += 3)); do
        local Input="${Test[i]-}"
        local ExpectedValue="${Test[i + 1]-}"
        local ReturnedValue="${Test[i + 2]-}"

        local -i InputPadSize ExpectedValuePadSize ReturnedValuePadSize
        InputPadSize=$((InputCols - ${#Input}))
        ExpectedValuePadSize=$((ExpectedValueCols - ${#ExpectedValue}))
        ReturnedValuePadSize=$((ReturnedValueCols - ${#ReturnedValue}))

        local InputPad ExpectedValuePad ReturnedValuePad
        InputPad="$(printf "%*s" ${InputPadSize})"
        ExpectedValuePad="$(printf "%*s" ${ExpectedValuePadSize})"
        ReturnedValuePad="$(printf "%*s" ${ReturnedValuePadSize})"

        if [[ ${ReturnedValue} == "${ExpectedValue}" ]]; then
            local SuccessLine
            SuccessLine="$(
                printf " | [${InputColor}%s${NC-}]${InputPad} | [${ExpectedColor}%s${NC-}]${ExpectedValuePad} | [${C["UnitTestPass"]-}%s${NC-}]${ReturnedValuePad} | " \
                    "${Input}" "${ExpectedValue}" "${ReturnedValue}"
            )"
            notice \
                "${SuccessLine}"
        else
            local FailLine
            FailLine="$(
                printf "${C["UnitTestFailArrow"]-}>${NC-}| [${C["UnitTestFail"]-}%s${NC-}]${InputPad} | [${C["UnitTestFail"]-}%s${NC-}]${ExpectedValuePad} | [${C["UnitTestFail"]-}%s${NC-}]${ReturnedValuePad} |${C["UnitTestFailArrow"]-}<${NC-}" \
                    "${Input}" "${ExpectedValue}" "${ReturnedValue}"
            )"
            error \
                "${FailLine}"
            result=1
        fi
    done
    notice \
        "${TableLine}"
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
