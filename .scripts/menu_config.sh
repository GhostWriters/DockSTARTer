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
    local OptionComposeUp="Start All Applications"
    local OptionComposeDown="Stop All Applications"
    local OptionDockerPrune="Prune Docker System"
    local ConfigOpts=(
        "${OptionFullSetup}" "This goes through selecting apps and editing variables. Recommended for first run"
        "${OptionSelectApps}" "Select which apps to run. Previously installed apps are remembered"
        "${OptionEditAppVars}" "Review and adjust variables for installed apps"
        "${OptionEditGlobalVars}" "Review and adjust global variables"
        "${OptionComposeUp}" "Run Docker Compose to start all applications"
        "${OptionComposeDown}" "Run Docker Compose to stop all applications"
        "${OptionDockerPrune}" "Remove all unused containers, networks, volumes, images and build cache"
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
                        ;;
                    "${OptionSelectApps}")
                        run_script_dialog "Updating variable files" "" 1 \
                            'env_update' || true
                        run_script 'menu_app_select' || true
                        ;;
                    "${OptionEditAppVars}")
                        clear
                        run_script 'menu_config_apps' || true
                        ;;
                    "${OptionEditGlobalVars}")
                        run_script_dialog "Updating variable files" "" 1 \
                            'env_update' || true
                        run_script 'menu_config_global' || true
                        ;;
                    "${OptionComposeUp}")
                        {
                            run_script 'yml_merge' || true
                            run_script 'docker_compose' "pull" || true
                            run_script 'docker_compose' "up" || true
                        } |& dialog_pipe "Docker Compose" "Starting all applications"
                        ;;
                    "${OptionComposeDown}")
                        {
                            run_script 'yml_merge' || true
                            run_script 'docker_compose' "down" || true
                        } |& dialog_pipe "Docker Compose" "Stopping all applications"
                        ;;
                    "${OptionDockerPrune}")
                        run_script_dialog "Prune Docker System" "" "" \
                            'docker_prune' || true
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
