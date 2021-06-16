#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'


update_check() {
    log "Checking for script updates."
    local REPO
    REPO="https://github.com/GhostWriters/DockSTARTer"
    local BRANCH
    BRANCH=$(git -C "${SCRIPTPATH}/${SCRIPTNAME}" branch --show-current)

    git -C "${SCRIPTPATH}/${SCRIPTNAME}" fetch origin "${BRANCH}" -q

    local LOCAL_COMMIT
    LOCAL_COMMIT=$(git -C "${SCRIPTPATH}/${SCRIPTNAME}" rev-parse @)
    local LOCAL_DIFF
    LOCAL_DIFF=$(git -C "${SCRIPTPATH}/${SCRIPTNAME}" diff)
    local REMOTE_BRANCH
    REMOTE_BRANCH=$(git -C "${SCRIPTPATH}/${SCRIPTNAME}" rev-parse --abbrev-ref --symbolic-full-name '@{u}')
    local REMOTE_DIFF
    REMOTE_DIFF=$(git -C "${SCRIPTPATH}/${SCRIPTNAME}" diff "${LOCAL_COMMIT}" "${REMOTE_BRANCH}")

    if [ "${LOCAL_DIFF}" != "" ]; then
        error "Your local files have changes that may conflict with performing an update. Please resolve this manually."
    elif [ "${REMOTE_DIFF}" != "" ]; then
        warn "New changes are available for ${BRANCH} script."
        warn "Review the changes: ${REPO%/}/compare/${LOCAL_COMMIT}...${BRANCH}"
        read -r -p "Press any key to continue." || fatal "Update canceled. Exiting."
        run_script 'update_self' "${BRANCH}"
    else
        info "${BRANCH} script is up to date."
    fi
}

test_update_check() {
    run_script 'update_check'
}
