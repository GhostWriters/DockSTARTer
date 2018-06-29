#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cmd_update() {
    run_script 'update_self'
    run_script 'run_apt'
    run_script 'install_yq' force
    run_script 'install_docker' force
    run_script 'install_machine_completion'
    run_script 'install_compose' force
    run_script 'install_compose_completion'
}
