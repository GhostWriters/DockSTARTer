#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

run_compose() {
    local COMPOSE_ARGS=${1:-}
    local MKTEMP_RUN_COMPOSE
    MKTEMP_RUN_COMPOSE=$(mktemp) || fatal "Failed to create temporary run compose script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run compose script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o "${MKTEMP_RUN_COMPOSE}" > /dev/null 2>&1 || fatal "Failed to get run compose script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o \"${MKTEMP_RUN_COMPOSE}\""
    docker pull ghcr.io/linuxserver/docker-compose:latest || fatal "Failed to pull latest docker-compose image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/docker-compose:latest"
    eval sh "${MKTEMP_RUN_COMPOSE}" "${COMPOSE_ARGS}" || fatal "Failed run compose script.\nFailing command: ${F[C]}sh \"${MKTEMP_RUN_COMPOSE}\" \"${COMPOSE_ARGS}\""
    rm -f "${MKTEMP_RUN_COMPOSE}" || warn "Failed to remove temporary run compose script."
}

test_run_compose() {
    run_script 'run_compose'
}
