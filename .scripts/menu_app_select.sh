#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_app_select() {
    local APPLIST
    APPLIST=()

    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line%%_ENABLED=*}
        local FILENAME
        FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    local APPNICENAME
                    APPNICENAME=$(grep --color=never -Po '^# APPNICENAME=\K.*' "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" || echo "${APPNAME}")
                    local APPDESCRIPTION
                    APPDESCRIPTION=$(grep --color=never -Po '^# APPDESCRIPTION=\K.*' "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" || echo "! Missing description !")
                    local APPONOFF
                    if [[ $(run_script 'env_get' "${APPNAME}_ENABLED") == true ]]; then
                        APPONOFF="on"
                    else
                        APPONOFF="off"
                    fi
                    APPLIST+=("${APPNICENAME}" "${APPDESCRIPTION}" "${APPONOFF}")
                fi
            fi
        fi
    done < <(grep '_ENABLED=' < "${SCRIPTPATH}/compose/.env")

    local SELECTEDAPPS
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        SELECTEDAPPS="Cancel"
    else
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer" --separate-output --checklist 'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.' 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi
    if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
        return 1
    else
        info "Disabling all apps."
        while IFS= read -r line; do
            local APPNAME
            APPNAME=${line%%_ENABLED=true}
            run_script 'env_set' "${APPNAME}_ENABLED" false
        done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")
        info "Enabling selected apps."
        while IFS= read -r line; do
            local APPNAME
            APPNAME=${line^^}
            run_script 'env_set' "${APPNAME}_ENABLED" true
        done < <(echo "${SELECTEDAPPS}")
    fi
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warning "Travis does not test menu_app_select."
}
