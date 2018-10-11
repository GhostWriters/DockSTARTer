#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

validate_shellcheck() {
    apt-get -y install xz-utils > /dev/null 2>&1 || fatal "Failed to install shellcheck dependencies from apt."
    export scversion="stable" # or "v0.4.7", or "latest"
    wget "https://storage.googleapis.com/shellcheck/shellcheck-${scversion}.linux.x86_64.tar.xz" || fatal "Failed to download shellcheck."
    tar --xz -xvf shellcheck-"${scversion}".linux.x86_64.tar.xz || fatal "Failed to extract shellcheck."
    cp shellcheck-"${scversion}"/shellcheck /usr/bin/ || fatal "Failed to copy shellcheck to bin."

    shellcheck --version || fatal "Failed to check shellcheck version."

    # Check for Shellcheck errors in the code.
    local SCERRORS
    SCERRORS=$(find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1090 -e SC1091 -e SC2034 || true)
    if [[ -n ${SCERRORS} ]]; then
        find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC2034
        fatal "Shellcheck validation failure."
    fi

    # Search for ShellCheck Warnings in all the scripts and fail if it finds any
    #    local SCDISABLED
    #    SCDISABLED=$(grep -r '^# shellcheck disable' "${SCRIPTPATH}" | grep -c 'shellcheck disable')
    #    if [[ ${SCDISABLED} -gt 0 ]]; then
    #        grep -rn "${SCRIPTPATH}" -e '^# shellcheck disable'
    #        fatal "Shellcheck validation failure."
    #    fi
}
