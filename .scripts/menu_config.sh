#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    local Title="Configuration Menu"
    local ConfigOpts=()
    ConfigOpts+=("Full Setup" "This goes through all menus below. Recommended for first run")
    ConfigOpts+=("Select Apps" "Select which apps to run. Previously enabled apps are remembered")
    ConfigOpts+=("Set App Variables" "Review and adjust variables for enabled apps")
    ConfigOpts+=("Set Global Variables" "Review and adjust global variables")

    local DIALOG_BUTTON_PRESSED
    local ConfigChoice
    if [[ ${CI-} == true ]]; then
        DIALOG_BUTTON_PRESSED=${DIALOG_CANCEL}
    else
        local -a ConfigChoiceDialog=(
            --clear
            --stdout
            --title "${Title}"
            --cancel-button "Exit"
            --menu "What would you like to do?" 0 0 0
            "${ConfigOpts[@]}"
        )
        DIALOG_BUTTON_PRESSED=0 && ConfigChoice=$(dialog "${ConfigChoiceDialog[@]}") || DIALOG_BUTTON_PRESSED=$?
    fi
    case ${DIALOG_BUTTON_PRESSED} in
        "${DIALOG_OK}")
            case "${ConfigChoice}" in
                "Full Setup")
                    clear
                    run_script 'env_migrate_global'
                    run_script 'env_update'
                    run_script 'config_global'
                    run_script 'menu_app_select'
                    run_script 'config_apps'
                    run_script 'yml_merge'
                    run_script 'docker_compose'
                    ;;
                "Set Global Variables")
                    clear
                    run_script 'env_migrate_global'
                    run_script 'env_update'
                    run_script 'config_global'
                    run_script 'yml_merge'
                    run_script 'docker_compose'
                    ;;
                "Select Apps")
                    clear
                    run_script 'env_migrate_global'
                    run_script 'env_update'
                    if run_script 'menu_app_select'; then
                        run_script 'yml_merge'
                        run_script 'docker_compose'
                    fi
                    ;;
                "Set App Variables")
                    clear
                    run_script 'env_migrate_global'
                    run_script 'env_update'
                    run_script 'config_apps'
                    run_script 'yml_merge'
                    run_script 'docker_compose'
                    ;;
                *)
                    error "Invalid Option"
                    ;;
            esac
            ;;
        "${DIALOG_CANCEL}" | "${DIALOG_ESC}")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            if [[ -n ${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]-} ]]; then
                clear
                fatal "Unexpected dialog button '${DIALOG_BUTTONS[$DIALOG_BUTTON_PRESSED]}' pressed."
            else
                clear
                fatal "Unexpected dialog button value'${DIALOG_BUTTON_PRESSED}' pressed."
            fi
            ;;
    esac
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
