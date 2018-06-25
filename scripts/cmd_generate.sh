#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cmd_generate() {
    run_script 'generate_yml'
    run_script 'run_compose'
}
