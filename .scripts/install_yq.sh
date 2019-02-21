#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_yq() {
    # https://github.com/mikefarah/yq
    local AVAILABLE_YQ
    AVAILABLE_YQ=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || fatal "Failed to check latest available yq version."
    local INSTALLED_YQ
    INSTALLED_YQ=$( (yq --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    local FORCE
    FORCE=${1:-}
    if vergt "${AVAILABLE_YQ}" "${INSTALLED_YQ}" || [[ -n ${FORCE} ]]; then
        info "Installing latest yq."
        if [[ ${ARCH} == "aarch64" ]] || [[ ${ARCH} == "armv7l" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_arm" -o /usr/local/bin/yq > /dev/null 2>&1 || fatal "Failed to install yq."
        fi
        if [[ ${ARCH} == "x86_64" ]]; then
            curl -H "${GH_HEADER:-}" -L "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_amd64" -o /usr/local/bin/yq > /dev/null 2>&1 || fatal "Failed to install yq."
        fi
        if [[ ! -L "/usr/bin/yq" ]]; then
            ln -s /usr/local/bin/yq /usr/bin/yq || fatal "Failed to create /usr/bin/yq symlink."
        fi
        chmod +x /usr/local/bin/yq > /dev/null 2>&1 || true
        local UPDATED_YQ
        UPDATED_YQ=$( (yq --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
        if vergt "${AVAILABLE_YQ}" "${UPDATED_YQ}"; then
            fatal "Failed to install the latest yq."
        fi
    fi
}
