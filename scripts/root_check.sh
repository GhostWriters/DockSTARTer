#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

root_check() {
    info "Checking root permissions."
    if [[ ${EUID} -ne 0 ]]; then
        sudo bash "${SCRIPTNAME:-}" "${ARGS[@]:-}" || fatal "Please run as root using sudo ds ${ARGS[*]:-}"
        exit
    fi
}
