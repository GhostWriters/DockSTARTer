#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Configuration Menu"
    local ConfigOpts=(
        "Full Setup" "This goes through all menus below. Recommended for first run"
        "Select Apps" "Select which apps to run. Previously enabled apps are remembered"
        "Set App Variables" "Review and adjust variables for enabled apps"
        "Set Global Variables" "Review and adjust global variables"
    )
    local -a ConfigChoiceDialog=(
        --clear
        --stdout
        --title "${Title}"
        --cancel-button "Back"
        --menu "What would you like to do?" 0 0 0
        "${ConfigOpts[@]}"
    )

    local LastConfigChoice=""
    while true; do
        local ConfigChoice
        local ConfigDialogButtonPressed=0
        ConfigChoice=$(dialog --default-item "${LastConfigChoice}" "${ConfigChoiceDialog[@]}") || ConfigDialogButtonPressed=$?
        LastConfigChoice=${ConfigChoice}
        case ${ConfigDialogButtonPressed} in
            "${DIALOG_OK}")
                case "${ConfigChoice}" in
                    "Full Setup")
                        clear
                        run_script 'env_migrate_global'
                        run_script 'env_update'
                        run_script 'config_global'
                        run_script 'menu_app_select' || true
                        run_script 'menu_config_apps'
                        run_script 'yml_merge'
                        run_script 'docker_compose' || true
                        ;;
                    "Set Global Variables")
                        clear
                        run_script 'env_migrate_global'
                        run_script 'env_update'
                        run_script 'config_global'
                        run_script 'yml_merge'
                        run_script 'docker_compose' || true
                        ;;
                    "Select Apps")
                        clear
                        run_script 'env_migrate_global'
                        run_script 'env_update'
                        run_script 'menu_app_select' || true
                        run_script 'yml_merge'
                        run_script 'docker_compose' || true
                        ;;
                    "Set App Variables")
                        clear
                        run_script 'env_migrate_global'
                        run_script 'env_update'
                        run_script 'menu_config_apps'
                        run_script 'yml_merge'
                        run_script 'docker_compose'
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
                clear
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[$ConfigDialogButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[$ConfigDialogButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value'${ConfigDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
