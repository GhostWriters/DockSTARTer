#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_yq() {
    local MINIMUM_YQ="3.2.1"
    local INSTALLED_YQ
    if [[ ${FORCE:-} == true ]] && [[ -n ${INSTALL:-} ]]; then
        INSTALLED_YQ="0"
    else
        INSTALLED_YQ=$( (yq-go --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    fi
    if vergt "${MINIMUM_YQ}" "${INSTALLED_YQ}"; then
        local AVAILABLE_YQ
        AVAILABLE_YQ=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_YQ} == "0" ]]; then
            if [[ ${INSTALLED_YQ} == "0" ]]; then
                fatal "The latest available version of yq-go could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warn "Failed to check latest available yq-go version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_YQ}" "${INSTALLED_YQ}"; then
            # https://github.com/mikefarah/yq
            info "Installing latest yq-go."
            local YQ_ARCH
            if [[ ${ARCH} == "aarch64" ]]; then
                YQ_ARCH="yq_linux_arm64"
            fi
            if [[ ${ARCH} == "armv7l" ]]; then
                YQ_ARCH="yq_linux_arm"
            fi
            if [[ ${ARCH} == "x86_64" ]]; then
                YQ_ARCH="yq_linux_amd64"
            fi
            curl -fsL "https://github.com/mikefarah/yq/releases/download/${AVAILABLE_YQ}/${YQ_ARCH}" -o /usr/local/bin/yq-go > /dev/null 2>&1 || fatal "Failed to install yq-go."
            chmod +x /usr/local/bin/yq-go > /dev/null 2>&1 || true
            if [[ ! -L "/usr/bin/yq-go" ]]; then
                rm -f /usr/bin/yq-go || warn "Failed to remove /usr/bin/yq-go"
                ln -s /usr/local/bin/yq-go /usr/bin/yq-go || fatal "Failed to create /usr/bin/yq-go symlink."
            fi
            local UPDATED_YQ
            UPDATED_YQ=$( (yq-go --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
            if vergt "${AVAILABLE_YQ}" "${UPDATED_YQ}"; then
                error "Failed to install the latest yq-go."
            fi
            if vergt "${MINIMUM_YQ}" "${UPDATED_YQ}"; then
                fatal "Failed to install the minimum required yq-go."
            fi
        fi
    fi
}

test_install_yq() {
    run_script 'install_yq'
    yq-go --version || fatal "Failed to determine yq-go version."
}
