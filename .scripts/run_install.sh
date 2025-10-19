#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

run_install() {
    local Title="Install Dependencies"
    local CommandLine="${CURRENT_COMMANDLINE:-${APPLICATION_COMMAND} --install}"
    local Question="Install or update all ${APPLICATION_NAME} dependencies?"
    local YesNotice="Installing or updating all ${APPLICATION_NAME} dependencies."
    local NoNotice="Not installing or updating all ${APPLICATION_NAME} dependencies."
    if run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
        if use_dialog_box; then
            {
                notice "${YesNotice}"
                run_install_commands
            } |& dialog_pipe "${DC["TitleSuccess"]-}${Title}" "${YesNotice}\n${DC["CommandLine"]-} ${CommandLine}"
        else
            notice "${YesNotice}"
            run_install_commands
        fi
    else
        if use_dialog_box; then
            notice "${NoNotice}" |& dialog_pipe "${DC["TitleError"]-}${Title}" "${NoNotice}"
        else
            notice "${NoNotice}"
        fi
    fi
}

run_install_commands() {
    run_script 'update_system'
    run_script 'require_docker'
    run_script 'setup_docker_group'
    run_script 'enable_docker_service'
    run_script 'request_reboot'
}

test_run_install() {
    run_script 'run_install'
}
