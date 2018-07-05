#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

root_check() {
    info "Checking root permissions."
    if [[ ${EUID} -ne 0 ]]; then
        fatal "Please run as root using sudo."
    fi
}
