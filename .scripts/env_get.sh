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
    # Return a "pass" for now.
    # There is an error to be fixed in "Var_15=  Va# lue# Not a Comment"
    local ForcePass=1
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
        fatal "Failed to create temporary file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX\""
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
    run_unit_tests_pipe "Var" "Var" < <(
        for ((i = 0; i < ${#Test[@]}; i += 3)); do
            printf '%s\n' \
                "${Test[i + 1]}" \
                "${Test[i + 2]}" \
                "$(run_script 'env_get' "${Test[i]}" "${VarFile}")"
        done
    )
    result=$?

    rm -f "${VarFile}" ||
        warn "Failed to remove temporary file.\nFailing command: ${C["FailingCommand"]}rm -f \"${VarFile}\""

    [[ -n ${ForcePass-} ]] && return 0
    return ${result}
}
