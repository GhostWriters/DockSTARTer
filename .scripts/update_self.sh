#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${F[C]}cd \"${SCRIPTPATH}\""
    local BRANCH CurrentBranch
    BRANCH=${1-$(git branch --show)}
    CurrentBranch="$(git branch --show)"
    local Title="Update DockSTARTer"
    local Question YesNotice NoNotice
    if [[ -z ${BRANCH-} ]]; then
        error "You need to specify a branch to update to."
        return 1
    fi
    if [[ ${BRANCH-} == "${CurrentBranch-}" ]]; then
        Question="Would you like to update DockSTARTer to branch ${BRANCH} now?"
        NoNotice="DockSTARTer will not be updated."
        YesNotice="Updating DockSTARTer to ${BRANCH}."
    else
        Question="Would you like to update DockSTARTer from branch ${CurrentBranch} to ${BRANCH} now?"
        NoNotice="DockSTARTer will not be updated from branch ${CurrentBranch} to ${BRANCH}."
        YesNotice="Updating DockSTARTer from branch ${CurrentBranch} to ${BRANCH}."
    fi
    if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        if use_dialog_box; then
            notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}" "${NoNotice}"
        else
            notice "${NoNotice}"
        fi
        return
    fi

    if use_dialog_box; then
        commands_update_self "${BRANCH}" |& dialog_pipe "${DC[TitleSuccess]}${Title}" "${YesNotice}\n${DC[CommandLine]} ds --update $*"
    else
        commands_update_self "${BRANCH}"
    fi
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
    git fetch --quiet --all --prune || fatal "Failed to fetch recent changes from git.\nFailing command: ${F[C]}git fetch --quiet --all --prune"
    if [[ ${CI-} != true ]]; then
        if [[ -n ${BRANCH-} ]]; then
            git switch --quiet --force "${BRANCH}" || fatal "Failed to switch to github branch ${BRANCH}.\nFailing command: ${F[C]}git switch --quiet --force \"${BRANCH}\""
            git reset --quiet --hard origin/"${BRANCH}" || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --quiet --hard origin/\"${BRANCH}\""
        else
            git reset --quiet --hard HEAD || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --quiet --hard HEAD"
        fi
        info "Pulling recent changes from git."
        git pull --quiet || fatal "Failed to pull recent changes from git.\nFailing command: ${F[C]}git pull --quiet"
    fi
    info "Cleaning up unnecessary files and optimizing the local repository."
    git gc > /dev/null 2>&1 || true
    info "Setting file ownership on new repository files"
    git ls-tree -rt --name-only "${BRANCH}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" > /dev/null 2>&1 || true
    sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}" > /dev/null 2>&1 || true
    exec bash "${SCRIPTNAME}" -e
}

test_update_self() {
    run_script 'update_self' "${COMMIT_SHA-}"
}
