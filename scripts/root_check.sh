#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

root_check() {
    if [[ ${EUID} -ne 0 ]]; then
        echo
        fatal "Please run as root using the command: sudo bash ${SCRIPTNAME}"
    fi
}
