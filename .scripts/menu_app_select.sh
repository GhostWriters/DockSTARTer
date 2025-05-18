#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_app_select() {
    local Title="Select Applications"
    dialog --title "${Title}" --infobox "Preparing app menu. Please be patient, this can take a while." 0 0
    local AppList=()
    local EnabledApps=()
    while IFS= read -r line; do
        local APPNAME=${line^^}
        local appname=${APPNAME
        APP_FOLDER="$(run_script 'instance_folder' "${APPNAME}")"
        if [[ -d ${APP_FOLDER}/ ]]; then
            local main_yml
            main_yml="$(run_script 'instance_file' "${APPNAME}" ".yml")"
            if [[ -f ${main_yml} ]]; then
                local main_yml
                arch_yml="$(run_script 'instance_file' "${APPNAME}" ".${ARCH}.yml")"
                if [[ -f ${arch_yml} ]]; then
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

    local -i SelectedAppsDialogButtonPressed
    local SelectedApps
    if [[ ${CI-} == true ]]; then
        SelectedAppsDialogButtonPressed=${DIALOG_CANCEL}
    else
        local -a SelectedAppsDialog=(
            --stdout
            --begin 2 2
            --colors
            --ok-label "Done"
            --cancel-label "Cancel"
            --title "${Title}"
            --separate-output
            --checklist
            'Choose which apps you would like to install:\n Use \Zr[up]\Zn, \Zr[down]\Zn, and \Zr[space]\Zn to select apps, and \Zr[tab]\Zn to switch to the buttons at the bottom.'
            $((LINES - 4)) $((COLUMNS - 5)) $((LINES - 5 - 4))
            "${AppList[@]}"
        )
        SelectedAppsDialogButtonPressed=0
        SelectedApps=$(dialog "${SelectedAppsDialog[@]}") || SelectedAppsDialogButtonPressed=$?
    fi
    case ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} in
        OK)
            {
                info "Disabling previously selected apps."
                run_script 'disable_app' "${EnabledApps[@]}"

                info "Enabling selected apps."
                run_script 'enable_app' "${SelectedApps}"
                run_script 'appvars_create' "${SelectedApps}"

                run_script 'appvars_purge_all'
                run_script 'env_update'
            } |& dialog_pipe "${Title}" "Enabling Selected Applications" 1
            return 0
            ;;
        CANCEL | ESC)
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]-} ]]; then
                clear
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[SelectedAppsDialogButtonPressed]}' pressed."
            else
                clear
                fatal "Unexpected dialog button value '${SelectedAppsDialogButtonPressed}' pressed."
            fi
            ;;
    esac
}

test_menu_app_select() {
    # run_script 'menu_app_select'
    warn "CI does not test menu_app_select."
}
