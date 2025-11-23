#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config() {
    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Configuration Menu"

    if run_script 'needs_appvars_create'; then
        coproc {
            dialog_pipe "${DC["TitleSuccess"]-}Creating environment variables for added apps" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --env" "${DIALOGTIMEOUT}"
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

    local Option_FullSetup="Full Setup"
    local Option_EditGlobalVars="Edit Global Variables"
    local Option_SelectApps="Select Applications"
    local Option_EditAppVars="Configure Applications"
    local Option_ComposeUp="Start All Applications"
    local Option_ComposeDown="Stop All Applications"
    local Option_DockerPrune="Prune Docker System"
    local ConfigOpts=(
        "${Option_FullSetup}" "${DC["ListDefault"]}This goes through selecting apps and editing variables. Recommended for first run"
        "${Option_EditGlobalVars}" "${DC["ListDefault"]}Review and adjust global variables"
        "${Option_SelectApps}" "${DC["ListDefault"]}Select which apps to run. Previously installed apps are remembered"
        "${Option_EditAppVars}" "${DC["ListDefault"]}Review and adjust variables for installed apps"
        "${Option_ComposeUp}" "${DC["ListDefault"]}Run Docker Compose to start all applications"
        "${Option_ComposeDown}" "${DC["ListDefault"]}Run Docker Compose to stop all applications"
        "${Option_DockerPrune}" "${DC["ListDefault"]}Remove all unused containers, networks, volumes, images and build cache"
    )

    local LastConfigChoice=""
    while true; do
        set_screen_size
        local -a ConfigChoiceDialog=(
            --output-fd 1
            --title "${DC["Title"]-}${Title}"
            --extra-button
            --ok-label "Select"
            --extra-label "Back"
            --cancel-label "Exit"
            --menu "What would you like to do?" 0 0 0
            "${ConfigOpts[@]}"
        )
        local ConfigChoice
        local -i ConfigDialogButtonPressed=0
        ConfigChoice=$(_dialog_ --default-item "${LastConfigChoice}" "${ConfigChoiceDialog[@]}") || ConfigDialogButtonPressed=$?
        LastConfigChoice=${ConfigChoice}
        case ${DIALOG_BUTTONS[ConfigDialogButtonPressed]-} in
            OK) # Select
                case "${ConfigChoice}" in
                    "${Option_FullSetup}")
                        run_script 'menu_config_vars' || true
                        run_script 'menu_app_select' || true
                        run_script 'menu_config_apps' || true
                        ;;
                    "${Option_EditGlobalVars}")
                        run_script 'menu_config_vars' || true
                        ;;
                    "${Option_SelectApps}")
                        run_script 'menu_app_select' || true
                        ;;
                    "${Option_EditAppVars}")
                        run_script 'menu_config_apps' || true
                        ;;
                    "${Option_ComposeUp}")
                        run_script 'docker_compose' "update"
                        ;;
                    "${Option_ComposeDown}")
                        local Question
                        Question="Would you like to ${DC["Highlight"]-}Stop${DC["NC"]-} all containers, or bring all containers ${DC["Highlight"]-}Down${DC["NC"]-}?\n\n${DC["Highlight"]-}Stop${DC["NC"]-} will stop them, ${DC["Highlight"]-}Down${DC["NC"]-} will stop and remove them."
                        local -a YesNoDialog=(
                            --title "${DC["TitleQuestion"]-}Docker Compose"
                            --no-collapse
                            --extra-button
                            --yes-label "Stop"
                            --extra-label "Down"
                            --no-label "Cancel"
                            --yesno "${Question}${DC["NC"]-}"
                            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                        )
                        local -i YesNoDialogButtonPressed=0
                        _dialog_ "${YesNoDialog[@]}" || YesNoDialogButtonPressed=$?
                        case ${DIALOG_BUTTONS[YesNoDialogButtonPressed]-} in
                            OK) # Stop
                                run_script_dialog "${DC["TitleSuccess"]-}Docker Compose" "Stopping all running services.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --compose stop" "" \
                                    'docker_compose' "stop"
                                ;;
                            EXTRA) # Down
                                run_script_dialog "${DC["TitleSuccess"]-}Docker Compose" "Stopping and removing all containers, networks, volumes, and images.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --compose down" "" \
                                    'docker_compose' "down"
                                ;;
                            CANCEL | ESC) # Cancel
                                ;;
                            *)
                                invalid_dialog_button \
                                    fatal ${YesNoDialogButtonPressed}
                                ;;
                        esac
                        ;;
                    "${Option_DockerPrune}")
                        run_script 'docker_prune'
                        ;;
                    *)
                        error "Invalid Option"
                        ;;
                esac
                ;;
            EXTRA | ESC) # Back
                return
                ;;
            CANCEL) # Exit
                run_script 'menu_exit'
                ;;
            *)
                invalid_dialog_button \
                    fatal ${ConfigDialogButtonPressed}
                ;;
        esac
    done
}

test_menu_config() {
    # run_script 'menu_config'
    warn "CI does not test menu_config."
}
