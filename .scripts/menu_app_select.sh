#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Apps"
    dialog --title "${Title}" --infobox "Preparing app menu. Please be patient, this can take a while." 0 0
    local AppList=()
    local EnabledApps=()
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

    local DIALOG_BUTTON_PRESSED
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        DIALOG_BUTTON_PRESSED=${DIALOG_CANCEL}
    else
        local -a SelectedAppsDialog=(
            --clear
            --stdout
            --title "${Title}"
            --separate-output
            --checklist
            'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.'
            0 0 0
            "${AppList[@]}"
        )
        DIALOG_BUTTON_PRESSED=0
        SelectedApps=$(dialog "${SelectedAppsDialog[@]}") || DIALOG_BUTTON_PRESSED=$?
    fi
    case ${DIALOG_BUTTON_PRESSED} in
        "${DIALOG_OK}")
            {
                info "Disabling previously selected apps."
                run_script 'disable_app' "${EnabledApps[@]}"

                info "Enabling selected apps."
                run_script 'enable_app' "${SelectedApps}"
                run_script 'appvars_create' "${SelectedApps}"

                run_script 'appvars_purge_all'
                run_script 'env_update'
            } |& ansifilter | dialog --clear --timeout 1 --title "${BACKTITLE}" --programbox "${Title}" -1 -1
            return 0
            ;;
        "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]-} ]]; then
                clear
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]}' pressed."
            else
                clear
                fatal "Unexpected dialog button value '${DIALOG_BUTTON_PRESSED}' pressed."
            fi
            ;;
    esac
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
