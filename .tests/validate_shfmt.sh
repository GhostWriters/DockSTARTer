#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

validate_shfmt() {
    info "Installing shfmt."
    local AVAILABLE_SHFMT
    AVAILABLE_SHFMT=$(curl -H "${GH_HEADER:-}" -s "https://api.github.com/repos/mvdan/sh/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")')
    # For some reason this isn't playing nice with Travis CI when the GH_HEADER is included.
    #curl -H "${GH_HEADER:-}" -L "https://github.com/mvdan/sh/releases/download/v${AVAILABLE_SHFMT}/shfmt_v${AVAILABLE_SHFMT}_$(uname -s | sed -e 's/\(.*\)/\L\1/')_amd64" -o /usr/local/bin/shfmt > /dev/null 2>&1 || fatal "Failed to install shfmt."
    curl -L "https://github.com/mvdan/sh/releases/download/v${AVAILABLE_SHFMT}/shfmt_v${AVAILABLE_SHFMT}_$(uname -s | sed -e 's/\(.*\)/\L\1/')_amd64" -o /usr/local/bin/shfmt > /dev/null 2>&1 || fatal "Failed to install shfmt."
    chmod +x /usr/local/bin/shfmt > /dev/null 2>&1 || true

    hash -r || true

    shfmt --version || fatal "Failed to check shfmt version."

    local VALIDATOR
    VALIDATOR=shfmt
    local VALIDATIONFLAGS
    VALIDATIONFLAGS="-s -i 4 -ci -sr -d"

    # https://github.com/caarlos0/shell-ci-build
    info "Linting all executables and .*sh files with ${VALIDATOR}..."
    while IFS= read -r line; do
        if head -n1 "${line}" | grep -q -E -w "sh|bash|dash|ksh"; then
            eval "${VALIDATOR} ${VALIDATIONFLAGS} ${SCRIPTPATH}/${line}" || fatal "Linting ${line}"
            info "Linting ${line}"
        else
            warning "Skipping ${line}..."
        fi
    done < <(git ls-tree -r HEAD | grep -E '^1007|.*\..*sh$' | awk '{print $4}')
    info "${VALIDATOR} validation complete."
}
