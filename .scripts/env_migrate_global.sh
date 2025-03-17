#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_migrate_global() {
    # Backup user files
    run_script 'env_backup'

    # Rename global vars
    run_script 'env_migrate' DOCKERCONFDIR DOCKER_VOLUME_CONFIG
    run_script 'env_migrate' DOCKERGID DOCKER_GID
    run_script 'env_migrate' DOCKERHOSTNAME DOCKER_HOSTNAME
    run_script 'env_migrate' DOCKERSTORAGEDIR DOCKER_VOLUME_STORAGE
    run_script 'env_migrate' DOCKERSHAREDDIR DOCKER_VOLUME_STORAGE
}

test_env_migrate_global() {
    warn "CI does not test env_migrate_global."
}
