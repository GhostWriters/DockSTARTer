#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_migrate_global() {
    # Rename global vars
    run_script 'env_migrate' DOCKERCONFDIR DOCKER_VOLUME_CONFIG
    run_script 'env_migrate' DOCKERGID DOCKER_GID
    run_script 'env_migrate' DOCKERHOSTNAME DOCKER_HOSTNAME
    run_script 'env_migrate' DOCKERSTORAGEDIR DOCKER_VOLUME_STORAGE
    run_script 'env_migrate' DOCKER_STORAGE DOCKER_STORAGE_ON
    run_script 'env_migrate' DOCKER_STORAGE2 DOCKER_STORAGE2_ON
    run_script 'env_migrate' DOCKER_STORAGE3 DOCKER_STORAGE3_ON
    run_script 'env_migrate' DOCKER_STORAGE4 DOCKER_STORAGE4_ON
    run_script 'env_migrate' LAN_NETWORK GLOBAL_LAN_NETWORK
    run_script 'env_migrate' NS1 GLOBAL_NS1
    run_script 'env_migrate' NS2 GLOBAL_NS2
}

test_env_migrate_global() {
    warn "CI does not test env_migrate_global."
}
