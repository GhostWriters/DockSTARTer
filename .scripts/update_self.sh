#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH
    BRANCH=${1:-origin/master}
    if run_script 'question_prompt' Y "Would you like to update DockSTARTer to ${BRANCH} now?"; then
        info "Updating DockSTARTer to ${BRANCH}."
    else
        info "DockSTARTer will not be updated to ${BRANCH}."
        return 1
    fi
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    git fetch --all --prune > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git."
    git reset --hard "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to ${BRANCH}."
    git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git."
    git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D > /dev/null 2>&1 || true
    while IFS= read -r line; do
        chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${line}" > /dev/null 2>&1 || true
    done < <(git ls-tree -r HEAD | awk '{print $4}')
    run_script 'env_update'
}

test_update_self() {
    run_script 'update_self' "${TRAVIS_COMMIT:-}"
}
