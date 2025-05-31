#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
    local Title="Docker Prune"
    if run_script 'question_prompt' Y "Would you like to remove all unused containers, networks, volumes, images and build cache?" "${DC["TitleWarning"]}${Title}" "${FORCE:+Y}"; then
        info "Removing unused docker resources."
    else
        info "Nothing will be removed."
        return 1
    fi

    local RUNCOMMAND="docker system prune --all --force --volumes"
    run_command_dialog "${Title}" "${RUNCOMMAND}" "" \
        eval "${RUNCOMMAND}" || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}${RUNCOMMAND}"
}

test_docker_prune() {
    run_script 'docker_prune'
}
