#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

run_yq() {
    local YQ_ARGS=${1:-}
    local MKTEMP_RUN_YQ
    MKTEMP_RUN_YQ=$(mktemp) || fatal "Failed to create temporary run yq script.\nFailing command: ${F[C]}mktemp"
    info "Downloading run yq script."
    curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh -o "${MKTEMP_RUN_YQ}" > /dev/null 2>&1 || fatal "Failed to get run yq script.\nFailing command: ${F[C]}curl -fsSL https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh -o \"${MKTEMP_RUN_YQ}\""
    docker pull ghcr.io/linuxserver/yq:latest || fatal "Failed to pull latest yq image.\nFailing command: ${F[C]}docker pull ghcr.io/linuxserver/yq:latest"
    eval sh "${MKTEMP_RUN_YQ}" "${YQ_ARGS}" || fatal "Failed to run yq script.\nFailing command: ${F[C]}sh \"${MKTEMP_RUN_YQ}\" \"${YQ_ARGS}\""
    rm -f "${MKTEMP_RUN_YQ}" || warn "Failed to remove temporary run yq script."
}

test_run_yq() {
    run_script 'run_yq'
}
