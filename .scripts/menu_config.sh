#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Configuration Menu"

    if [[ -n ${PROCESS_APPVARS_CREATE_ALL} ]]; then
        coproc {
            dialog_pipe "${DC[TitleSuccess]}Creating environment variables for added apps" "Please be patient, this can take a while.\n${DC[CommandLine]} ${APPLICATION_COMMAND} --env" "${DIALOGTIMEOUT}"
        }
        local -i DialogBox_PID=${COPROC_PID}
        local -i DialogBox_FD="${COPROC[1]}"
        {
            run_script 'env_backup'
            run_script 'appvars_create_all' || true
        } >&${DialogBox_FD} 2>&1
        exec {DialogBox_FD}<&-
        wait ${DialogBox_PID}
    fi

    local OptionFullSetup="Full Setup"
    local OptionEditGlobalVars="Edit Global Variables"
    local OptionSelectApps="Select Applications"
    local OptionEditAppVars="Configure Applications"
    local OptionComposeUp="Start All Applications"
    local OptionComposeDown="Stop All Applications"
    local OptionDockerPrune="Prune Docker System"
    local ConfigOpts=(
        "${OptionFullSetup}" "This goes through selecting apps and editing variables. Recommended for first run"
        "${OptionEditGlobalVars}" "Review and adjust global variables"
        "${OptionSelectApps}" "Select which apps to run. Previously installed apps are remembered"
        "${OptionEditAppVars}" "Review and adjust variables for installed apps"
        "${OptionComposeUp}" "Run Docker Compose to start all applications"
        "${OptionComposeDown}" "Run Docker Compose to stop all applications"
        "${OptionDockerPrune}" "Remove all unused containers, networks, volumes, images and build cache"
    )

    local LastConfigChoice=""
    while true; do
        local -a ConfigChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]}${Title}"
            --ok-label "Select"
            --cancel-label "Back"
            --menu "What would you like to do?" 0 0 0
            "${ConfigOpts[@]}"
        )
        local ConfigChoice
        local -i ConfigDialogButtonPressed=0
        ConfigChoice=$(_dialog_ --default-item "${LastConfigChoice}" "${ConfigChoiceDialog[@]}") || ConfigDialogButtonPressed=$?
        LastConfigChoice=${ConfigChoice}
        case ${DIALOG_BUTTONS[ConfigDialogButtonPressed]-} in
            OK)
                case "${ConfigChoice}" in
                    "${OptionFullSetup}")
                        run_script 'menu_config_vars' || true
                        run_script 'menu_app_select' || true
                        run_script 'menu_config_apps' || true
                        ;;
                    "${OptionEditGlobalVars}")
                        run_script 'menu_config_vars' || true
                        ;;
                    "${OptionSelectApps}")
                        run_script 'menu_app_select' || true
                        ;;
                    "${OptionEditAppVars}")
                        run_script 'menu_config_apps' || true
                        ;;
                    "${OptionComposeUp}")
                        run_script 'docker_compose' "update"
                        ;;
                    "${OptionComposeDown}")
                        local Question
                        Question="Would you like to ${DC["Highlight"]}Stop${DC[NC]} all containers, or bring all containers ${DC["Highlight"]}Down${DC[NC]}?\n\n${DC["Highlight"]}Stop${DC[NC]} will stop them, ${DC["Highlight"]}Down${DC[NC]} will stop and remove them."
                        local -a YesNoDialog=(
                            --title "${DC["TitleQuestion"]}Docker Compose"
                            --no-collapse
                            --extra-button
                            --yes-label "Stop"
                            --extra-label "Down"
                            --no-label "Cancel"
                            --yesno "${Question}${DC[NC]}"
                            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                        )
                        local -i YesNoDialogButtonPressed=0
                        _dialog_ "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
                        case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                            OK) # Stop
                                run_script_dialog "${DC["TitleSuccess"]}Docker Compose" "Stopping all running services.\n${DC["CommandLine"]} ${APPLICATION_COMMAND} --compose stop" "" \
                                    'docker_compose' "stop"
                                ;;
                            EXTRA) # Down
                                run_script_dialog "${DC["TitleSuccess"]}Docker Compose" "Stopping and removing all containers, networks, volumes, and images.\n${DC["CommandLine"]} ${APPLICATION_COMMAND} --compose down" "" \
                                    'docker_compose' "down"
                                ;;
                            CANCEL | ESC) ;; # Cancel
                            *)
                                if [[ -n ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} ]]; then
                                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[YesNoDialogButtonPressed]}' pressed in menu_config."
                                else
                                    fatal "Unexpected dialog button value '${YesNoDialogButtonPressed}' pressed in menu_config."
                                fi
                                ;;
                        esac
                        ;;
                    "${OptionDockerPrune}")
                        run_script 'docker_prune'
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
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[ConfigDialogButtonPressed]}' pressed in menu_config."
                else
                    fatal "Unexpected dialog button value '${ConfigDialogButtonPressed}' pressed in menu_config."
                fi
                ;;
        esac
    done
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
