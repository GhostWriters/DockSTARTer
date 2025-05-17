#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

varname_is_valid() {
    local VarName=${1-}
    local VarType=${2-}
    case "${VarType-}" in
        "")
            # <no argument>
            # Accepts any variable type
            ;;
        "_BARE_")
            # _BARE_
            # Accepts a bare variable, no appname specified.
            [[ ${VarName} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
            return
            ;;
        "_GLOBAL_")
            # _GLOBAL_
            # Accepts a global variable.  It connot be a variable for an app
            if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                [[ $(run_script 'varname_to_appname' "${VarName}") == "" ]]
                return
            fi
            false
            return
            ;;
        "_APPNAME_")
            # _APPNAME_
            # Accepts a variable for any app.  It must be upper case, and it must be in the form "APPNAME__VARNAME"
            if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                [[ $(run_script 'varname_to_appname' "${VarName}") != "" ]]
                return
            fi
            false
            return
            ;;
        "_APPNAME_:")
            # _APPNAME_:
            # Accepts a variable in any "appname.env" file (specifies "appname:varname")
            local AppName="${VarName%:*}"
            if run_script 'appname_is_valid' "${AppName}"; then
                run_script 'varname_is_valid' "${VarName#${VarType}:*}" "_BARE_"
                return
            fi
            false
            return
            ;;
        *":")
            # <appname>:
            # Accepts a variable in "appname.env" file (specifies "appname:varname")
            local AppName="${VarName%:*}"
            if [[ ${AppName^^} == "${VarType^^}" ]]; then
                run_script 'varname_is_valid' "${VarName#${VarType}:*}" "_BARE_"
                return
            fi
            false
            return
            ;;
        *)
            # <appname>
            # Accepts a variable for the specified app.  It must be upper case and in the form "APPNAME__VARNAME"
            if run_script 'varname_is_valid' "${VarName-}" "_BARE_"; then
                [[ $(run_script 'varname_to_appname' "${VarName}") == "${VarType^^}" ]]
                return
            fi
            false
            return
            ;;
    esac
}

test_varname_is_valid() {
    for VarType in "" _BARE_ _GLOBAL_ _APPNAME_ "_APPNAME_:" "radarr:" "radarr"; do
        notice "[${VarType}]"
        for VarName in "radarr:varname" TZ RADARR_4K RADARR__TAG Radarr__TAG RADARR__4K__TAG RADARR__4K__tag; do
            if run_script 'varname_is_valid' "${VarName}" "${VarType}"; then
                notice "             [*VALID*] [${VarName}]"
            else
                notice "                       [${VarName}]"
            fi
        done
    done
}
