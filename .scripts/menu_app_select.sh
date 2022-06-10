#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local APPLIST=()
    notice "Preparing app menu. Please be patient, this can take a while."
    while IFS= read -r line; do
        local APPNAME=${line^^}
        local FILENAME=${APPNAME,,}
        local APPTEMPLATES="${SCRIPTPATH}/compose/.apps/${FILENAME}"
        if [[ -d ${APPTEMPLATES}/ ]]; then
            if [[ -f ${APPTEMPLATES}/${FILENAME}.yml ]]; then
                if [[ -f ${APPTEMPLATES}/${FILENAME}.${ARCH}.yml ]]; then
                    local APPNICENAME
                    APPNICENAME=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.nicename: \K.*" "${APPTEMPLATES}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "${APPNAME}")
                    local APPDESCRIPTION
                    APPDESCRIPTION=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.description: \K.*" "${APPTEMPLATES}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo "! Missing description !")
                    local APPDEPRECATED
                    APPDEPRECATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${APPTEMPLATES}/${FILENAME}.labels.yml" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)
                    if [[ ${APPDEPRECATED} == true ]]; then
                        continue
                    fi
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
    if [[ ${CI-} == true ]]; then
        SELECTEDAPPS="Cancel"
    else
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer" --separate-output --checklist 'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.' 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi
    if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
        return 1
    else
        info "Disabling all apps."
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=*}
            run_script 'env_set' "${APPNAME}_ENABLED" false
        done < <(grep --color=never -P '_ENABLED='"'"'?true'"'"'?$' "${COMPOSE_ENV}")

        info "Enabling selected apps."
        while IFS= read -r line; do
            local APPNAME=${line^^}
            run_script 'appvars_create' "${APPNAME}"
            run_script 'env_set' "${APPNAME}_ENABLED" true
        done < <(echo "${SELECTEDAPPS}")

        run_script 'appvars_purge_all'
        run_script 'env_update'
    fi
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
