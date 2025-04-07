#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
    local Title="Docker Prune"
    if run_script 'question_prompt' Y "Would you like to remove all unused containers, networks, volumes, images and build cache?" "${Title}"; then
        info "Removing unused docker resources."
    else
        info "Nothing will be removed."
        return 1
    fi

    local RUNCOMMAND="docker system prune --all --force --volumes"
    if [[ ${PROMPT:-CLI} == GUI && -t 1 ]]; then
        {
            eval "${RUNCOMMAND}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
        } |& dialog --begin 2 2 --title "${Title}" --programbox "${RUNCOMMAND}" $((LINES - 4)) $((COLUMNS - 5))

    else
        eval "${RUNCOMMAND}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
    fi
}

test_docker_prune() {
    run_script 'docker_prune'
}
