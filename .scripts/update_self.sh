#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    local BRANCH CurrentBranch
    BRANCH=${1-$(git branch --show)}
    CurrentBranch="$(git branch --show)"
    local Title="Update DockSTARTer"
    local Question Notice
    if [[ -z ${BRANCH-} ]]; then
        error "You need to specify a branch to update to."
        return 1
    fi
    if [[ ${BRANCH-} == "${CurrentBranch-}" ]]; then
        Question="Would you like to update DockSTARTer now?"
        Notice="DockSTARTer will not be updated."
    else
        Question="Would you like to update DockSTARTer from branch ${CurrentBranch} to ${BRANCH} now?"
        Notice="DockSTARTer will not be updated from ${CurrentBranch} to ${BRANCH}."
    fi
    if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        notice "${Notice}"
        return 1
    fi

    if use_dialog_box; then
        commands_update_self "${BRANCH}" |& dialog_pipe "${Title}" "Updating DockSTARTer to ${BRANCH}"
    else
        commands_update_self "${BRANCH}"
    fi
    #exec bash "${SCRIPTNAME}" -e
}

commands_update_self() {
    local BRANCH=${1-}
    notice "Clearing instances folder"
    rm -R "${INSTANCES_FOLDER:?}/"* &> /dev/null || true
    notice "Updating DockSTARTer to ${BRANCH}."
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    info "Setting file ownership on current repository files"
    sudo chown -R "$(id -u)":"$(id -g)" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "$(id -u)":"$(id -g)" "${SCRIPTPATH}" > /dev/null 2>&1 || true
    git ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" > /dev/null 2>&1 || true

    info "Fetching recent changes from git."
    git fetch --all --prune || fatal "Failed to fetch recent changes from git.\nFailing command: ${F[C]}git fetch --all --prune"
    if [[ ${CI-} != true ]]; then
        if [[ -n ${BRANCH-} ]]; then
            git switch --force "${BRANCH}" || fatal "Failed to switch to github branch ${BRANCH}.\nFailing command: ${F[C]}git switch --force \"${BRANCH}\""
            git reset --hard origin/"${BRANCH}" || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --hard origin/\"${BRANCH}\""
        else
            git reset --hard HEAD || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --hard HEAD"
        fi
        info "Pulling recent changes from git."
        git pull || fatal "Failed to pull recent changes from git.\nFailing command: ${F[C]}git pull"
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
