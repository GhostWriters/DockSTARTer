#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local BackTitle="DockSTARTer"
    local Title="Select Apps"
    local AppList=()
    local EnabledApps=()
    notice "Preparing app menu. Please be patient, this can take a while."
    while IFS= read -r line; do
        local APPNAME=${line^^}
        local appname=${APPNAME,,}
        local APP_FOLDER="${TEMPLATES_FOLDER}/${appname}"
        if [[ -d ${APP_FOLDER}/ ]]; then
            if [[ -f ${APP_FOLDER}/${appname}.yml ]]; then
                if [[ -f ${APP_FOLDER}/${appname}.${ARCH}.yml ]]; then
                    local AppName
                    AppName=$(run_script 'app_nicename' "${APPNAME}")
                    local AppDescription
                    AppDescription=$(run_script 'app_description' "${APPNAME}")
                    local AppOnOff
                    if run_script 'app_is_enabled' "${APPNAME}"; then
                        AppOnOff="on"
                        EnabledApps+=("${AppName}")
                    else
                        AppOnOff="off"
                    fi
                    AppList+=("${AppName}" "${AppDescription}" "${AppOnOff}")
                fi
            fi
        fi
    done < <(run_script 'app_list_nondepreciated')

    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedApps="Cancel"
    else
        local -a SelectedAppsDialog=(
            --fb
            --clear
            --backtitle "${BackTitle}"
            --title "${Title}"
            --separate-output
            --checklist
            'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.'
            0 0 0
            "${AppList[@]}"
        )
        SelectedApps=$(dialog "${SelectedAppsDialog[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        clear
    fi
    if [[ ${SelectedApps} == "Cancel" ]]; then
        return 1
    else
        info "Disabling previously selected apps."
        run_script 'disable_app' "${EnabledApps[@]}"

        info "Enabling selected apps."
        run_script 'enable_app' "${SelectedApps}"
        run_script 'appvars_create' "${SelectedApps}"

        run_script 'appvars_purge_all'
        run_script 'env_update'
    fi
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
