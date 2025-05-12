#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Configuration Menu"

    local OptionFullSetup="Full Setup"
    local OptionSelectApps="Select Apps"
    local OptionEditAppVars="Edit App Variables"
    local OptionEditGlobalVars="Edit Global Variables"
    local ConfigOpts=(
        "${OptionFullSetup}" "This goes through all menus below. Recommended for first run"
        "${OptionSelectApps}" "Select which apps to run. Previously enabled apps are remembered"
        "${OptionEditAppVars}" "Review and adjust variables for enabled apps"
        "${OptionEditGlobalVars}" "Review and adjust global variables"
    )
    local -a ConfigChoiceDialog=(
        --stdout
        --title "${Title}"
        --ok-label "Select"
        --cancel-label "Back"
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
                    "${OptionFullSetup}")
                        run_script_dialog "Updating variable files" "" 1 \
                            'env_update' || true
                        run_script 'menu_config_global' || true
                        run_script 'menu_app_select' || true
                        run_script 'menu_config_apps' || true
                        run_script_dialog "Merging and running Docker Compose" "" 1 \
                            'merge_and_compose' || true
                        ;;
                    "${OptionSelectApps}")
                        run_script_dialog "Updating variable files" "" 1 \
                            'env_update' || true
                        run_script 'menu_app_select' || true
                        run_script_dialog "Merging and running Docker Compose" "" 1 \
                            'merge_and_compose' || true
                        ;;
                    "${OptionEditAppVars}")
                        clear
                        run_script 'menu_config_apps' || true
                        run_script_dialog "Merging and running Docker Compose" "" 1 \
                            'merge_and_compose' || true
                        ;;
                    "${OptionEditGlobalVars}")
                        run_script_dialog "Updating variable files" "" 1 \
                            'env_update' || true
                        run_script 'menu_config_global' || true
                        run_script_dialog "Merging and running Docker Compose" "" 1 \
                            'merge_and_compose' || true
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
