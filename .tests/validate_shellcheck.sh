#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

validate_shellcheck() {
    info "Installing shellcheck."
    apt-get -y install xz-utils > /dev/null 2>&1 || fatal "Failed to install shellcheck dependencies from apt."
    export scversion="stable" # or "v0.4.7", or "latest"
    wget "https://storage.googleapis.com/shellcheck/shellcheck-${scversion}.linux.x86_64.tar.xz" > /dev/null 2>&1 || fatal "Failed to download shellcheck."
    tar --xz -xvf "shellcheck-${scversion}.linux.x86_64.tar.xz" > /dev/null 2>&1 || fatal "Failed to extract shellcheck."
    cp "shellcheck-${scversion}/shellcheck" /usr/bin/ || fatal "Failed to copy shellcheck to bin."
    rm -rf "shellcheck-${scversion}.linux.x86_64.tar.xz" "shellcheck-${scversion}/shellcheck" || true

    shellcheck --version || fatal "Failed to check shellcheck version."

    local VALIDATOR
    VALIDATOR=shellcheck
    local VALIDATIONFLAGS
    VALIDATIONFLAGS="-x"

    # https://github.com/caarlos0/shell-ci-build
    echo "Linting all executables and .*sh files with ${VALIDATOR}..."
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
