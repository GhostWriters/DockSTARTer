#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Test Runner Function
run_test() {
    local SCRIPTSNAME=${1-}
    shift
    local TESTSNAME="test_${SCRIPTSNAME}"
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        if grep -q -P "${TESTSNAME}" "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"; then
            notice "Testing '${C["RunningCommand"]-}${SCRIPTSNAME}${NC-}'."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
            "${TESTSNAME}" "$@" || fatal "Failed to run '${C["FailingCommand"]-}${TESTSNAME}${NC-}'."
            notice "Completed testing '${C["RunningCommand"]-}${TESTSNAME}${NC-}'."
        else
            fatal "Test function in '${C["File"]-}${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh${NC-}' not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
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
    notice "${TableLine}"
    notice "${Heading}"
    notice "${TableLine}"
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
                printf " | [${InputColor}%s${NC-}]${InputPad} | [${ExpectedColor}%s${NC-}]${ExpectedValuePad} | [${C["Notice"]-}%s${NC-}]${ReturnedValuePad} | " \
                    "${Input}" "${ExpectedValue}" "${ReturnedValue}"
            )"
            notice "${SuccessLine}"
        else
            local FailLine
            FailLine="$(
                printf "${C["Error"]-}>${NC-}| [${C["Error"]-}%s${NC-}]${InputPad} | [${C["Error"]-}%s${NC-}]${ExpectedValuePad} | [${C["Error"]-}%s${NC-}]${ReturnedValuePad} |${C["Error"]-}<${NC-}" \
                    "${Input}" "${ExpectedValue}" "${ReturnedValue}"
            )"
            error "${FailLine}"
            result=1
        fi
    done
    notice "${TableLine}"
    if [[ -n ${ForcePass} ]]; then
        warn "The '${C["Var"]-}ForcePass${NC-}' variable is set."
        if [[ ${result} != 0 ]]; then
            error "Passing test even though an error occurred."
            return 0
        fi
    fi
    return ${result}
}
