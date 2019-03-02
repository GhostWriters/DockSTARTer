#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

prune_docker() {
    if run_script 'question_prompt' Y "Would you like to remove all unused containers, networks, volumes, images and build cache?"; then
        info "Removing unused docker resources."
    else
        info "Nothing will be removed."
        return 1
    fi
    docker system prune -a --volumes --force || error "Failed to remove unused docker resources."
}

test_prune_docker() {
    run_script 'prune_docker'
}
