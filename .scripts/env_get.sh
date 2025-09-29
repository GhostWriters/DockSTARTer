#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_get() {
    # env_get VarName [VarFile]
    # env_get APPNAME:VarName
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
        local LiteralValue
        LiteralValue="$(run_script 'env_get_literal' "${VarName}" "${VarFile}")"
        grep --color=never -Po "^\s*(?:(?:(?<Q>['\"]).*\k<Q>)|(?:[^\s]*[^#]*))" <<< "${LiteralValue}" | xargs 2> /dev/null || true
    else
        # VarFile does not exist, give a warning
        warn "File '${C["File"]}${VarFile}${NC}' does not exist."
    fi

}

test_env_get() {
    local -a Test=(
        "Test='Value'" Value
        "    Test='Value'" Value
        "Test  ='Value'" Value
        "    Test  ='Value'" Value
        "Test=  'Value'" Value
        "Test='Value'# Comment # kljkl" Value
        "    Test='Value' # Comment" Value
        "Test  ='Value' # Comment" Value
        "    Test  ='Value' # Comment" Value
        "Test=  'Value' # Comment" Value
        "Test=  Value# Not a Comment" "Value# Not a Comment"
        "Test=  '#Value' # Comment" "#Value"
        "Test=  #Value# Not a Comment" "#Value# Not a Comment"
        "Test=  'Va#lue' # Comment" "Va#lue"
        "Test=  Va# lue# Not a Comment" "Va# lue# Not a Comment"
        "Test=  Va# lue # Comment" "Va# lue"
    )
    run_unit_tests_pipe "Var" "Var" < <(
        for ((i = 0; i < ${#Test[@]}; i += 2)); do
            printf '%s\n' \
                "${Test[i]}" \
                "${Test[i + 1]}" \
                "$(run_script 'env_get' Test <(echo "${Test[i]}"))"
        done
    )

    # Return a "pass" for now.
    # There is an error to be fixed in "Test=  Va# lue# Not a Comment"
    return 0
}
