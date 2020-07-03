#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    run_script 'update_system'
    run_script 'install_docker'
    run_script 'install_machine_completion'
    run_script 'setup_docker_group'
    run_script 'enable_docker_systemd'
    run_script 'install_compose'
    run_script 'install_compose_completion'
    run_script 'install_yq'
    run_script 'request_reboot'
}

test_run_install() {
    run_script 'run_install'
}
