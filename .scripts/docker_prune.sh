#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
    local Title="Docker Prune"
    Question="Would you like to remove all unused containers, networks, volumes, images and build cache?"
    YesNotice="Removing unused docker resources."
    NoNotice="Nothing will be removed."

    local RUNCOMMAND="docker system prune --all --force --volumes"
    if run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        if use_dialog_box; then
            {
                notice "${YesNotice}"
                eval "${RUNCOMMAND}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
            } |& dialog_pipe "${DC[TitleSuccess]}${Title}" "${DC[RV]}${YesNotice}${DC[NC]}\n${DC[CommandLine]} ${RUNCOMMAND}"
        else
            notice "${YesNotice}"
            eval "${RUNCOMMAND}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
        fi
    else
        if use_dialog_box; then
            notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}"
        else
            notice "${NoNotice}"
        fi
    fi
}

test_docker_prune() {
    run_script 'docker_prune'
}
