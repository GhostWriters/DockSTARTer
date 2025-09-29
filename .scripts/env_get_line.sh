#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get_line() {
    # env_get_line VarName [VarFile]
    # env_get_line APPNAME:VarName
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
        grep --color=never -Po "^\s*${VarName}\s*=.*" "${VarFile}" | tail -1 || true
    else
        # VarFile does not exist, give a warning
        warn "${F[C]}${VarFile}${NC} does not exist."
    fi

}

test_env_get_line() {
    local -a Test=(
        "Test='Value'" "Test='Value'"
        "    Test='Value'" "    Test='Value'"
        "Test  ='Value'" "Test  ='Value'"
        "    Test  ='Value'" "    Test  ='Value'"
        "Test=  'Value'" "Test=  'Value'"
        "Test='Value'# Comment # kljkl" "Test='Value'# Comment # kljkl"
        "    Test='Value' # Comment" "    Test='Value' # Comment"
        "Test  ='Value' # Comment" "Test  ='Value' # Comment"
        "    Test  ='Value' # Comment" "    Test  ='Value' # Comment"
        "Test=  'Value' # Comment" "Test=  'Value' # Comment"
        "Test=  Value# Not a Comment" "Test=  Value# Not a Comment"
        "Test=  '#Value' # Comment" "Test=  '#Value' # Comment"
        "Test=  #Value# Not a Comment" "Test=  #Value# Not a Comment"
        "Test=  'Va#lue' # Comment" "Test=  'Va#lue' # Comment"
        "Test=  Va# lue# Not a Comment" "Test=  Va# lue# Not a Comment"
        "Test=  Va# lue # Comment" "Test=  Va# lue # Comment"
    )
    #shellcheck disable=SC2046 #(warning): Quote this to prevent word splitting.
    run_unit_tests "Var" "Var" $(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'env_get_line' Test <(echo "${Test[i]}"))"
        done
    )
}
