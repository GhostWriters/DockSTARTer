#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

install_yq() {
    local MINIMUM_YQ="2.0"
    local INSTALLED_YQ
    if [[ ${FORCE:-} == true ]] && [[ -n ${INSTALL:-} ]]; then
        INSTALLED_YQ="0"
    else
        INSTALLED_YQ=$( (yq --version 2> /dev/null || echo "0") | sed -E 's/(\S+ )(version )?([0-9][a-zA-Z0-9_.-]*)(, build .*)?/\3/')
    fi
    local YQ_HELP
    YQ_HELP=$(yq --help 2> /dev/null || true)
    if ! echo "${YQ_HELP}" | grep -q 'kislyuk'; then
        INSTALLED_YQ="0"
        warn "Wrong version of yq detected. https://github.com/kislyuk/yq will be installed."
    fi
    if vergt "${MINIMUM_YQ}" "${INSTALLED_YQ}"; then
        local AVAILABLE_YQ
        AVAILABLE_YQ=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/kislyuk/yq/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_YQ} == "0" ]]; then
            if [[ ${INSTALLED_YQ} == "0" ]]; then
                fatal "The latest available version of yq could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warn "Failed to check latest available yq version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_YQ}" "${INSTALLED_YQ}"; then
            local PREVIOUS_YQ
            PREVIOUS_YQ=$(docker images --no-trunc --format '{{.ID}} {{.Repository}}' | grep 'yq' | awk '{ print $1 }' | xargs) || true
            if [[ -n ${PREVIOUS_YQ} ]]; then
                info "Removing previous yq images."
                docker rmi "${PREVIOUS_YQ}" 2> /dev/null || true
            fi
            # https://github.com/linuxserver/docker-yq/blob/master/README.md#recommended-method
            info "Installing latest yq."
            curl -fsL "https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh" -o /usr/local/bin/yq > /dev/null 2>&1 || fatal "Failed to install yq.\nFailing command: ${F[C]}curl -fsL \"https://raw.githubusercontent.com/linuxserver/docker-yq/master/run-yq.sh\" -o /usr/local/bin/yq"
            chmod +x /usr/local/bin/yq > /dev/null 2>&1 || true
            if [[ ! -L "/usr/bin/yq" ]]; then
                rm -f /usr/bin/yq || warn "Failed to remove /usr/bin/yq"
                ln -s /usr/local/bin/yq /usr/bin/yq || fatal "Failed to create /usr/bin/yq symlink.\nFailing command: ${F[C]}ln -s /usr/local/bin/yq /usr/bin/yq"
            fi
            local UPDATED_YQ
            UPDATED_YQ=$( (yq --version 2> /dev/null || echo "0") | sed -E 's/(\S+ )(version )?([0-9][a-zA-Z0-9_.-]*)(, build .*)?/\3/')
            if vergt "${AVAILABLE_YQ}" "${UPDATED_YQ}"; then
                error "Failed to install the latest yq."
            fi
            if vergt "${MINIMUM_YQ}" "${UPDATED_YQ}"; then
                fatal "Failed to install the minimum required yq."
            fi
        fi
    fi
}

test_install_yq() {
    run_script 'install_yq'
    yq --version || fatal "Failed to determine yq version.\nFailing command: ${F[C]}yq --version"
}
