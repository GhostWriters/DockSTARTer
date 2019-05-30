#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_app_select() {
    run_script 'install_yq'
    local APPLIST=()

    while IFS= read -r line; do
        local APPNAME=${line^^}
        local FILENAME=${APPNAME,,}
        if [[ -d ${SCRIPTPATH}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ -f ${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    local APPNICENAME
                    APPNICENAME=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appinfo.nicename]" || echo "${APPNAME}")
                    local APPDESCRIPTION
                    APPDESCRIPTION=$(run_script 'yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appinfo.description]" || echo "! Missing description !")
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
    done < <(ls -A "${SCRIPTPATH}/compose/.apps/")

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
            local APPNAME=${line%%_ENABLED=true}
            run_script 'env_set' "${APPNAME}_ENABLED" false
        done < <(grep '_ENABLED=true$' < "${SCRIPTPATH}/compose/.env")

        info "Enabling selected apps."
        while IFS= read -r line; do
            local APPNAME=${line^^}
            run_script 'appvars_create' "${APPNAME}"
            run_script 'env_set' "${APPNAME}_ENABLED" true
        done < <(echo "${SELECTEDAPPS}")

        info "Purging disabled app variables."
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=false}
            run_script 'appvars_purge' "${APPNAME}"
        done < <(grep '_ENABLED=false$' < "${SCRIPTPATH}/compose/.env")
    fi
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warning "Travis does not test menu_app_select."
}
