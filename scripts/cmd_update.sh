#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cmd_update() {
    run_script 'update_self'
    run_script 'root_check'
    run_script 'run_apt'
    run_script 'install_yq'
    run_script 'install_docker'
    run_script 'install_machine_completion'
    run_script 'install_compose'
    run_script 'install_compose_completion'
}
