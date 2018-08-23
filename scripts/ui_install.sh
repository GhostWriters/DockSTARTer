#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ui_install() {
    run_script 'update_system'
    run_script 'install_yq' force
    run_script 'install_docker' force
    run_script 'install_machine_completion'
    run_script 'install_compose' force
    run_script 'install_compose_completion'
    run_script 'setup_docker_group'
    run_script 'enable_docker_systemd'
    run_script 'request_reboot' menu || return 1
}
