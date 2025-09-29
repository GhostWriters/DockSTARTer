#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get_literal() {
    # env_get_literal VarName [VarFile]
    # env_get_literal APPNAME:VarName
    #
    # The string returned will be the literal value after `=`, including quotes and comments
    #
    # Returns the variable "VarName"  If no "VarFile" is given, uses the global .env file
    # If "APPNAME:" is provided, gets variable from ".env.app.appname"
    local VarName=${1-}
    local VarFile=${2:-$COMPOSE_ENV}

    if ! run_script 'varname_is_valid' "${VarName}"; then
        error "${F[C]}${VarName}${NC} is an invalid variable name."
        return
    fi

    if [[ ${VarName} =~ ^[A-Za-z0-9_]+: ]]; then
        # VarName is in the form of "APPNAME:VARIABLE", set new file to use
        local APPNAME=${VarName%%:*}
        VarFile="$(run_script 'app_env_file' "${APPNAME}")"
        VarName=${VarName#"${APPNAME}:"}
    fi
    if [[ -e ${VarFile} ]]; then
        local Line
        Line="$(run_script 'env_get_line' "${VarName}" "${VarFile}")"
        echo "${Line#*=}"
    else
        # VarFile does not exist, give a warning
        warn "${F[C]}${VarFile}${NC} does not exist."
    fi

}

test_env_get_literal() {
    local -a Test=(
        "Test='Value'" "'Value'"
        "    Test='Value'" "'Value'"
        "Test  ='Value'" "'Value'"
        "    Test  ='Value'" "'Value'"
        "Test=  'Value'" "  'Value'"
        "Test='Value'# Comment # kljkl" "'Value'# Comment # kljkl"
        "    Test='Value' # Comment" "'Value' # Comment"
        "Test  ='Value' # Comment" "'Value' # Comment"
        "    Test  ='Value' # Comment" "'Value' # Comment"
        "Test=  'Value' # Comment" "  'Value' # Comment"
        "Test=  Value# Not a Comment" "  Value# Not a Comment"
        "Test=  '#Value' # Comment" "  '#Value' # Comment"
        "Test=  #Value# Not a Comment" "  #Value# Not a Comment"
        "Test=  'Va#lue' # Comment" "  'Va#lue' # Comment"
        "Test=  Va# lue# Not a Comment" "  Va# lue# Not a Comment"
        "Test=  Va# lue # Comment" "  Va# lue # Comment"
    )
    #shellcheck disable=SC2046 #(warning): Quote this to prevent word splitting.
    run_unit_tests "Var" "Var" $(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'env_get_literal' Test <(echo "${Test[i]}"))"
        done
    )
}
