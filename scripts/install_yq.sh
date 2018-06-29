#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

install_yq() {
    # # https://github.com/mikefarah/yq
    local AVAILABLE_YQ
    AVAILABLE_YQ=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    local INSTALLED_YQ
    INSTALLED_YQ=$( (yq --version || true) | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if [[ "${AVAILABLE_YQ}" != "${INSTALLED_YQ}" ]] || [[ -n ${FORCE} ]]; then
        if [[ ${ARCH} == "arm64" ]] || [[ ${ARCH} == "armhf" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_arm" -o /usr/local/bin/yq
        fi
        if [[ ${ARCH} == "amd64" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_amd64" -o /usr/local/bin/yq
        fi
        chmod +x /usr/local/bin/yq || true
    fi
}
