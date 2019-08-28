#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

docker_prune() {
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to remove all unused containers, networks, volumes, images and build cache?"; then
        info "Removing unused docker resources."
    else
        info "Nothing will be removed."
        return 1
    fi
    docker system prune -a --volumes --force || error "Failed to remove unused docker resources."
}

test_docker_prune() {
    run_script 'docker_prune'
}
