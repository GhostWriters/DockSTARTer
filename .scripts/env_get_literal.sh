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
    if [[ -f ${VarFile} ]]; then
        local Line
        Line="$(run_script 'env_get_line' "${VarName}" "${VarFile}")"
        echo "${Line#*=}"
    else
        # VarFile does not exist, give a warning
        warn "${F[C]}${VarFile}${NC} does not exist."
    fi

}

test_env_get_literal() {
    local VarFile
    VarFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.VarFile.XXXXXXXXXX")
    cat > "${VarFile}" << EOF
Test1='Value'
    Test2='Value'
Test3  ='Value'
    Test4  ='Value'
Test5=  'Value'
Test6='Value'# Comment # kljkl
    Test7='Value' # Comment
Test8  ='Value' # Comment
    Test9  ='Value' # Comment
Test10=  'Value' # Comment
Test11=  Value# Comment
Test12=  '#Value' # Comment
Test13=  #Value# Comment
Test14=  'Va#lue' # Comment
Test15=  Va# lue# Comment
Test16=  Va# lue # Comment

EOF

    cat "${VarFile}"
    for Number in {1..16}; do
        notice "[Test${Number}] [$(run_script 'env_get_literal' "Test${Number}" "${VarFile}")]"
    done
    rm -f "${VarFile}"
}
