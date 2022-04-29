#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

docker_prune() {
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to remove all unused containers, networks, volumes, images and build cache?"; then
        info "Removing unused docker resources."
    else
        info "Nothing will be removed."
        return 1
    fi
    docker system prune -a --volumes --force || error "Failed to remove unused docker resources.\nFailing command: ${F[C]}docker system prune -a --volumes --force"
}

test_docker_prune() {
    run_script 'docker_prune'
}
