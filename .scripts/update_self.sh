#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH=${1:-origin/master}
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to update DockSTARTer to ${BRANCH} now?"; then
        notice "Updating DockSTARTer to ${BRANCH}."
    else
        notice "DockSTARTer will not be updated to ${BRANCH}."
        return 1
    fi
    cd "${SCRIPTPATH}" || fatal "Failed to change to ${SCRIPTPATH} directory."
    info "Fetching recent changes from git."
    git fetch --all --prune > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git."
    info "Resetting to ${BRANCH}."
    git reset --hard "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to ${BRANCH}."
    if [[ ${CI:-} != true ]]; then
        info "Pulling recent changes from git."
        git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git."
    fi
    info "Removing unused branches."
    git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D > /dev/null 2>&1 || true
    while IFS= read -r line; do
        info "Setting file ownership on ${line}"
        chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${line}" > /dev/null 2>&1 || true
    done < <(git ls-tree -r HEAD | awk '{print $4}')
    run_script 'env_update'
    run_script 'appvars_create_all'
}

test_update_self() {
    run_script 'update_self' "${COMMIT_SHA:-}"
}
