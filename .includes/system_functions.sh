#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Check for supported CPU architecture
check_arch() {
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
}

# Check if the repo exists relative to the SCRIPTPATH
check_repo() {
    if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
        return
    else
        return 1
    fi
}

# Check if running as root
check_root() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as '${C["User"]}root${NC}' is not supported. Please run as a standard user."
    fi
}

# Check if running with sudo
check_sudo() {
    if [[ ${EUID} -eq 0 ]]; then
        fatal "Running with '${C["UserCommand"]}sudo${NC}' is not supported. Commands requiring '${C["UserCommand"]}sudo${NC}' will prompt automatically when required."
    fi
}
