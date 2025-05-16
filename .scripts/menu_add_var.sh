#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_var() {
    local APPNAME=${1-}
    local appname
    local AppName
    local VarFile
    local VarType
    local DescriptionHeading
    local VarFile="${COMPOSE_ENV}"

    # shellcheck source=./menu_color_definitions.sh
    source "${SCRIPTPATH}/.scripts/menu_color_definitions.sh"

    if [[ -z ${APPNAME-} ]]; then
        # No appname specified, creating a global variable in .env
        VarType="GLOBAL"
        Title="Add Global Variable"
        VarFile="${COMPOSE_ENV}"
        DescriptionHeading="File: ${ColorHeading}${VarFile}\Zn\n"
    else
        Title="Add Application Variable"
        if [[ ${APPNAME} == *":" ]]; then
            # appname: specified, creating a variable in appname.env
            VarType="APPENV"
            APPNAME="${APPNAME%:}"
            appname=${APPNAME,,}
            VarFile="${APP_ENV_FOLDER}/${appname}.env"
        else
            # appname specified, creating an APPNAME__* variable in .env
            VarType="APP"
            appname="${APPNAME,,}"
            VarFile="${COMPOSE_ENV}"
        fi
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
        # editorconfig-checker-disable
        DescriptionHeading="

Application: ${ColorHeading}${AppName}\Zn
       File: ${ColorHeading}${VarFile}\Zn"
        # editorconfig-checker-enable
    fi
    dialog --colors --cr-wrap --no-collapse --title "${Title}" --msgbox "${DescriptionHeading}\n\nAdd a variable" 0 0
}
test_menu_add_var() {
    # run_script 'menu_add_var'
    warn "CI does not test menu_add_var."
}
