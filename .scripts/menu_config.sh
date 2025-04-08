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
        --stdout
        --title "${Title}"
        --cancel-button "Back"
        --menu "What would you like to do?" 0 0 0
        "${ConfigOpts[@]}"
    )

    local LastConfigChoice=""
    while true; do
        local ConfigChoice
        local -i ConfigDialogButtonPressed=0
        ConfigChoice=$(dialog --default-item "${LastConfigChoice}" "${ConfigChoiceDialog[@]}") || ConfigDialogButtonPressed=$?
        LastConfigChoice=${ConfigChoice}
        case ${DIALOG_BUTTONS[ConfigDialogButtonPressed]-} in
            OK)
                case "${ConfigChoice}" in
                    "Full Setup")
                        run_script 'env_update' || true
                        run_script 'menu_config_global' || true
                        run_script 'menu_app_select' || true
                        run_script 'menu_config_apps' || true
                        run_script 'merge_and_compose' || true
                        ;;
                    "Set Global Variables")
                        run_script 'env_update' || true
                        run_script 'menu_config_global' || true
                        run_script 'merge_and_compose' || true
                        ;;
                    "Select Apps")
                        run_script 'env_update' || true
                        run_script 'menu_app_select' || true
                        run_script 'merge_and_compose' || true
                        ;;
                    "Set App Variables")
                        clear
                        run_script 'menu_config_apps' || true
                        run_script 'merge_and_compose' || true
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[ConfigDialogButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[ConfigDialogButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value '${ConfigDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
