#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    local BRANCH=${1-$(git branch --show)}
    if run_script 'question_prompt' "${PROMPT-}" Y "Would you like to update DockSTARTer to ${BRANCH} now?"; then
        notice "Updating DockSTARTer to ${BRANCH}."
    else
        notice "DockSTARTer will not be updated to ${BRANCH}."
        return 1
    fi
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    info "Setting file ownership on current repository files"
    sudo chown -R "$(id -u)":"$(id -g)" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "$(id -u)":"$(id -g)" "${SCRIPTPATH}" > /dev/null 2>&1 || true
    git ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" > /dev/null 2>&1 || true
    info "Fetching recent changes from git."
    git fetch --all --prune > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git.\nFailing command: ${F[C]}git fetch --all --prune"
    if [[ ${CI-} != true ]]; then
        info "Resetting to ${BRANCH}."
        git switch --force "${BRANCH}" > /dev/null 2>&1 || fatal "Failed to switch to github branch ${BRANCH}.\nFailing command: ${F[C]}git switch --force \"${BRANCH}\""
        git reset --hard origin/"${BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --hard origin/\"${BRANCH}\""

        info "Pulling recent changes from git."
        git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git.\nFailing command: ${F[C]}git pull"
    fi
    info "Cleaning up unnecessary files and optimizing the local repository."
    git gc > /dev/null 2>&1 || true
    info "Setting file ownership on new repository files"
    git ls-tree -rt --name-only "${BRANCH}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" > /dev/null 2>&1 || true
    sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}" > /dev/null 2>&1 || true
}

test_update_self() {
    run_script 'update_self' "${COMMIT_SHA-}"
}
