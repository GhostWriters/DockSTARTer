#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_yq() {
    local MINIMUM_YQ="2.0.0"
    local INSTALLED_YQ
    INSTALLED_YQ=$( (/usr/local/bin/yq-go --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    if vergt "${MINIMUM_YQ}" "${INSTALLED_YQ}"; then
        local AVAILABLE_YQ
        AVAILABLE_YQ=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_YQ} == "0" ]]; then
            if [[ ${INSTALLED_YQ} == "0" ]]; then
                fatal "The latest available version of yq-go could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warning "Failed to check latest available yq-go version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_YQ}" "${INSTALLED_YQ}"; then
            # https://github.com/mikefarah/yq
            info "Installing latest yq-go."
            if [[ ${ARCH} == "aarch64" ]] || [[ ${ARCH} == "armv7l" ]]; then
                curl -fsL "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_arm" -o /usr/local/bin/yq-go > /dev/null 2>&1 || fatal "Failed to install yq-go."
            fi
            if [[ ${ARCH} == "x86_64" ]]; then
                curl -fsL "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/yq_linux_amd64" -o /usr/local/bin/yq-go > /dev/null 2>&1 || fatal "Failed to install yq-go."
            fi
            if [[ ! -L "/usr/bin/yq-go" ]]; then
                ln -s /usr/local/bin/yq-go /usr/bin/yq-go || fatal "Failed to create /usr/bin/yq-go symlink."
            fi
            chmod +x /usr/local/bin/yq-go > /dev/null 2>&1 || true
            local UPDATED_YQ
            UPDATED_YQ=$( (/usr/local/bin/yq-go --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
            if vergt "${AVAILABLE_YQ}" "${UPDATED_YQ}"; then
                fatal "Failed to install the latest yq-go."
            fi
        fi
    fi
}

test_install_yq() {
    run_script 'install_yq'
    /usr/local/bin/yq-go --version || fatal "Failed to determine yq-go version."
}
