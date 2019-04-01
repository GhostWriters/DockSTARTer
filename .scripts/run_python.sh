#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_python() {
    if [[ -n "$(command -v python3.7)" ]]; then
        eval python3.7 "$@"
    elif [[ -n "$(command -v python3.6)" ]]; then
        eval python3.6 "$@"
    elif [[ -n "$(command -v python3.5)" ]]; then
        eval python3.5 "$@"
    elif [[ -n "$(command -v python3.4)" ]]; then
        eval python3.4 "$@"
    elif [[ -n "$(command -v python3.3)" ]]; then
        eval python3.3 "$@"
    elif [[ -n "$(command -v python3)" ]]; then
        eval python3 "$@"
    else
        fatal "Python3 manager not detected!"
    fi
}

test_run_python() {
    run_script 'run_python' --version
    warning "Travis does not test run_python."
}
