#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_python() {
    # https://devguide.python.org/#status-of-python-branches
    local PYTHON_CMD
    if [[ -n "$(command -v python3.7)" ]]; then
        PYTHON_CMD="python3.7"
        # EOL: 2023-06-27
    elif [[ -n "$(command -v python3.6)" ]]; then
        PYTHON_CMD="python3.6"
        # EOL: 2021-12-23
    elif [[ -n "$(command -v python3.5)" ]]; then
        PYTHON_CMD="python3.5"
        # EOL: 2020-09-13
    elif [[ -n "$(command -v python3)" ]]; then
        PYTHON_CMD="python3"
    else
        fatal "Python3 manager not detected!"
    fi

    eval "${PYTHON_CMD}" "$@" || return 1
}

test_run_python() {
    run_script 'run_python' --version
    run_script 'run_python' -m pip --version
}
