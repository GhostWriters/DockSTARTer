#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH=${1:-origin/master}
    if run_script 'question_prompt' "${PROMPT:-}" Y "Would you like to update DockSTARTer to ${BRANCH} now?"; then
        notice "Updating DockSTARTer to ${BRANCH}."
    else
        notice "DockSTARTer will not be updated to ${BRANCH}."
        return 1
    fi
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    info "Fetching recent changes from git."
    git fetch --all --prune > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git.\nFailing command: ${F[C]}git fetch --all --prune"
    if [[ ${CI:-} != true ]]; then
        info "Resetting to ${BRANCH}."
        git reset --hard "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to ${BRANCH}.\nFailing command: ${F[C]}git reset --hard \"${BRANCH}\""
        info "Pulling recent changes from git."
        git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git.\nFailing command: ${F[C]}git pull"
    fi
    info "Cleaning up unnecessary files and optimizing the local repository."
    git gc > /dev/null 2>&1 || true
    # git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D > /dev/null 2>&1 || true
    info "Setting file ownership on repository files"
    git ls-tree -r HEAD | awk '{print $4}' | xargs chown "${DETECTED_PUID}":"${DETECTED_PGID}" > /dev/null 2>&1 || true
    chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    run_script 'env_update'
    run_script 'appvars_create_all'
}

test_update_self() {
    run_script 'update_self' "${COMMIT_SHA:-}"
}
