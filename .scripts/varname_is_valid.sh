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
            ;;
        "_GLOBAL_")
            # _GLOBAL_
            # Accepts a global variable.  It connot be a variable for an app
            ;;
        "_APPNAME_")
            # _APPNAME_
            # Accepts a variable for any app.  It must be upper case, and it must be in the form "APPNAME__VARNAME"
            ;;
        "_APPNAME_:")
            # _APPNAME_:
            # Accepts a variable in any "appname.env" file (specifies "appname:varname")
            ;;
        *":")
            # <appname>:
            # Accepts a variable in "appname.env" file (specifies "appname:varname")
            ;;
        *)
            # <appname>
            # Accepts a variable for the specified app.  It must be upper case and in the form "APPNAME__VARNAME"
            ;;
    esac
}

test_varname_is_valid() {
    for VarName in SONARR Sonarr SONARR_4K SONARR__4K "SONARR 4K" "SONARR:"; do
        if run_script 'varname_is_valid' "${VarName}"; then
            notice "[${VarName}] is valid"
        else
            notice "[${VarName}] is not valid"
        fi
    done
}
