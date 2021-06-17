#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_check() {
    log "Checking for script updates."
    local REPO
    REPO="https://github.com/GhostWriters/DockSTARTer"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    local BRANCH
    BRANCH=$(git branch --show-current)

    info "Fetching recent changes from git."
    git fetch --all --prune > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git.\nFailing command: ${F[C]}git fetch --all --prune"

    local LOCAL_COMMIT
    LOCAL_COMMIT=$(git rev-parse @)
    local LOCAL_DIFF
    LOCAL_DIFF=$(git diff)
    local REMOTE_BRANCH
    REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')
    local REMOTE_DIFF
    REMOTE_DIFF=$(git diff "${LOCAL_COMMIT}" "${REMOTE_BRANCH}")

    if [ "${LOCAL_DIFF}" != "" ]; then
        error "Your local files have changes that may conflict with performing an update. Please resolve this manually."
    elif [ "${REMOTE_DIFF}" != "" ]; then
        warn "New changes are available for ${BRANCH} branch."
        warn "Review the changes: ${REPO%/}/compare/${LOCAL_COMMIT}...${BRANCH}"
        warn "If the above link does not show any changes, you may be using a testing branch."
        if [[ ${CI:-} != true ]]; then
            read -rp "Press any key to continue." < /dev/tty || sleep 10
        fi
        run_script 'update_self' "${BRANCH}"
    else
        info "${BRANCH} branch is up to date."
    fi
}

test_update_check() {
    run_script 'update_check'
}
