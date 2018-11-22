#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

validate_shellcheck() {
    local VALIDATOR
    VALIDATOR="docker run --rm -v ${SCRIPTPATH}:${SCRIPTPATH} koalaman/shellcheck"
    local VALIDATIONFLAGS
    VALIDATIONFLAGS="-x"
    local VALIDATORVERFLAG
    VALIDATORVERFLAG="--version"

    eval "${VALIDATOR} ${VALIDATORVERFLAG}" || fatal "Failed to check ${VALIDATOR} version."

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
