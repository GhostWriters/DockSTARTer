#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

validate_bashate() {
    info "Installing bashate."
    pip install -U bashate > /dev/null 2>&1 || fatal "Failed to install bashate from pip."

    bashate --show || fatal "Failed to check bashate version."

    local VALIDATOR
    VALIDATOR=bashate
    local VALIDATIONFLAGS
    VALIDATIONFLAGS="-i E006"

    # https://github.com/caarlos0/shell-ci-build
    echo "Linting all executables and .*sh files with ${VALIDATOR}..."
    while IFS= read -r line; do
        if grep -q -E -w "sh|bash|dash|ksh" "${line}"; then
            eval "${VALIDATOR} ${VALIDATIONFLAGS} ${SCRIPTPATH}/${line}" || fatal "Linting ${line}"
            info "Linting ${line}"
        else
            info "Skipping ${line}..."
        fi
    done < <(git ls-tree -r HEAD | grep -E '^1007|.*\..*sh$' | awk '{print $4}')
    info "${VALIDATOR} validation complete."
}
