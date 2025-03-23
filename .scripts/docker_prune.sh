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

    local REDIRECT=""
    if [[ ${PROMPT:-CLI} == GUI ]]; then
        REDIRECT="2>&1 | dialog --title \"${Title}\" --programbox \"\${RUNCOMMAND}\" -1 -1"
    fi
    local RUNCOMMAND="docker system prune --all --force --volumes"
    eval "${RUNCOMMAND} ${REDIRECT}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
}

test_docker_prune() {
    run_script 'docker_prune'
}
