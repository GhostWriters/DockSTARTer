#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ds_version() {
    local Branch Version
    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${F[C]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null

    # Get the branch
    Branch="$(git symbolic-ref --short -q HEAD)"
    # Get the current tag. If no tag, use the commit instead.
    Version="$(git describe --tags --exact-match 2> /dev/null)" || Version="commit $(git rev-parse --short HEAD)"

    echo "${Branch} ${Version}"
    popd &> /dev/null
}

test_ds_version() {
    notice "DockSTARTer version: $(run_script 'ds_version')"
}
