#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH
    BRANCH=${1-$(git branch --show)}

    local Title="Update DockSTARTer"
    if ! run_script 'question_prompt' Y "Would you like to update DockSTARTer to ${BRANCH} now?" "${DC["TitleWarning"]}${Title}" "${FORCE:+Y}"; then
        notice "DockSTARTer will not be updated to ${BRANCH}."
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
    if [[ ${CI-} != true ]]; then
        if [[ -n ${BRANCH-} ]]; then
            git switch --force "${BRANCH}" || fatal "Failed to switch to github branch ${BRANCH}.\nFailing command: ${F[C]}git switch --force \"${BRANCH}\""
        fi
        git reset --hard HEAD || fatal "Failed to reset to current branch.\nFailing command: ${F[C]}git reset --hard git HEAD"
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
