#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ds_branch() {
    pushd "${SCRIPTPATH}" &> /dev/null ||
        fatal \
            "Failed to change directory." \
            "Failing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null || true
    git symbolic-ref --short HEAD 2> /dev/null || true
    popd &> /dev/null
}

ds_branch_exists() {
    local CurrentBranch
    CurrentBranch="$(ds_branch)"
    local CheckBranch
    CheckBranch=${1:-"${CurrentBranch}"}

    pushd "${SCRIPTPATH}" &> /dev/null ||
        fatal \
            "Failed to change directory." \
            "Failing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    local -i result=0
    git ls-remote --exit-code --heads origin "${CheckBranch}" &> /dev/null || result=$?
    popd &> /dev/null
    return ${result}
}

ds_version() {
    local CheckBranch
    CheckBranch=${1-}
    local commitish Branch
    if [[ -n ${CheckBranch-} ]]; then
        commitish="origin/${CheckBranch}"
        Branch="${CheckBranch}"
    else
        commitish='HEAD'
        Branch="$(ds_branch)"
    fi

    pushd "${SCRIPTPATH}" &> /dev/null ||
        fatal \
            "Failed to change directory." \
            "Failing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    if [[ -z ${CheckBranch-} ]] || ds_branch_exists "${Branch}"; then
        # Get the current tag. If no tag, use the commit instead.
        local VersionString
        VersionString="$(git describe --tags --exact-match "${commitish}" 2> /dev/null || true)"
        if [[ -z ${VersionString-} ]]; then
            VersionString="commit $(git rev-parse --short "${commitish}" 2> /dev/null || true)"
        fi
        VersionString="${Branch} ${VersionString}"
    else
        VersionString=''
    fi
    echo "${VersionString}"
    popd &> /dev/null
}
ds_update_available() {
    pushd "${SCRIPTPATH}" &> /dev/null ||
        fatal \
            "Failed to change directory." \
            "Failing command: ${C["FailingCommand"]}pushd \"${SCRIPTPATH}\""
    git fetch --quiet &> /dev/null
    local -i result=0
    # shellcheck disable=SC2319 # This $? refers to a condition, not a command. Assign to a variable to avoid it being overwritten.
    [[ $(git rev-parse HEAD 2> /dev/null) != $(git rev-parse '@{u}' 2> /dev/null) ]] || result=$?
    popd &> /dev/null
    return ${result}
}

ds_switch_branch() {
    local CurrentBranch
    CurrentBranch="$(ds_branch)"
    if [[ ${CurrentBranch} == "${SOURCE_BRANCH}" ]] && ds_branch_exists "${TARGET_BRANCH}"; then
        export FORCE=true
        export PROMPT="CLI"
        notice \
            "Automatically switching from ${APPLICATION_NAME} branch '${C["Branch"]}${SOURCE_BRANCH}${NC}' to '${C["Branch"]}${TARGET_BRANCH}${NC}'."
        run_script 'update_self' "${TARGET_BRANCH}" "${ARGS[@]}"
        exit
    fi
}
