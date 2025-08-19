#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
    local BRANCH CurrentBranch CurrentVersion RemoteVersion
    BRANCH=${1-}
    shift || true
    if [[ ${BRANCH-} == "${SOURCE_BRANCH}" ]] && ds_branch_exists "${TARGET_BRANCH}"; then
        warn "Updating to branch '${F[C]}${TARGET_BRANCH}${NC}' instead of '${F[C]}${SOURCE_BRANCH}${NC}'."
        BRANCH="${TARGET_BRANCH}"
    fi

    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}push \"${SCRIPTPATH}\""
    CurrentBranch="$(ds_branch)"
    CurrentVersion="$(ds_version)"
    local Title="Update ${APPLICATION_NAME}"
    local Question YesNotice NoNotice
    if [[ -z ${BRANCH-} ]]; then
        if [[ -z ${CurrentBranch-} ]]; then
            error "You need to specify a branch to update to."
            return 1
        fi
        RemoteVersion="$(ds_version "${CurrentBranch}")"
        Question="Would you like to update ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}' now?"
        NoNotice="${APPLICATION_NAME} will not be updated."
        YesNotice="Updating ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
    elif [[ ${BRANCH-} == "${CurrentBranch-}" ]]; then
        RemoteVersion="$(ds_version "${BRANCH}")"
        if [[ ${CurrentVersion} == "${RemoteVersion}" ]]; then
            Question="Would you like to forcefully re-apply ${APPLICATION_NAME} update '${C["Version"]}${CurrentVersion}${NC}'?"
            NoNotice="${APPLICATION_NAME} will not be updated."
            YesNotice="Updating ${APPLICATION_NAME} to '${C["Version"]}${RemoteVersion}${NC}'"
        else
            Question="Would you like to update ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}' now?"
            NoNotice="${APPLICATION_NAME} will not be updated from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
            YesNotice="Updating ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
        fi
    else
        RemoteVersion="$(ds_version "${BRANCH}")"
        Question="Would you like to update ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}' now?"
        NoNotice="${APPLICATION_NAME} will not be updated from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
        YesNotice="Updating ${APPLICATION_NAME} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
    fi
    popd &> /dev/null

    if ! ds_branch_exists "${BRANCH}"; then
        BRANCH="${BRANCH:-"${CurrentBranch}"}"
        local ErrorMessage="${APPLICATION_NAME} branch '${C["Branch"]}${BRANCH}${NC}' does not exists."
        if use_dialog_box; then
            error "${ErrorMessage}" |&
                dialog_pipe "${DC[TitleError]}${Title}" "${DC[CommandLine]} ${APPLICATION_COMMAND} --update $*"
        else
            error "${ErrorMessage}"
        fi
        return 1
    fi
    if [[ -z ${BRANCH-} && ${CurrentVersion} == "${RemoteVersion}" ]]; then
        if use_dialog_box; then
            {
                notice "${APPLICATION_NAME} is already up to date on branch '${C["Branch"]}${CurrentBranch}${NC}'."
                notice "Current version is '${C["Version"]}${CurrentVersion}${NC}'"
            } |& dialog_pipe "${DC[TitleWarning]}${Title}" "${DC[CommandLine]} ${APPLICATION_COMMAND} --update $*"
        else
            notice "${APPLICATION_NAME} is already up to date on branch '${C["Branch"]}${CurrentBranch}${NC}'."
            notice "Current version is '${C["Version"]}${CurrentVersion}${NC}'"
        fi
        return 0
    fi

    BRANCH="${BRANCH:-"${CurrentBranch}"}"
    if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${FORCE:+Y}"; then
        if use_dialog_box; then
            notice "${NoNotice}" |& dialog_pipe "${DC[TitleError]}${Title}" "${NoNotice}"
        else
            notice "${NoNotice}"
        fi
        return 1
    fi

    declare -gx PROCESS_APPVARS_CREATE_ALL=1
    declare -gx PROCESS_ENV_UPDATE=1
    declare -gx PROCESS_YML_MERGE=1

    if use_dialog_box; then
        commands_update_self "${BRANCH}" "${YesNotice}" "$@" |&
            dialog_pipe "${DC[TitleSuccess]}${Title}" "${YesNotice}\n${DC[CommandLine]} ${APPLICATION_COMMAND} --update $*"
    else
        commands_update_self "${BRANCH}" "${YesNotice}" "$@"
    fi
}

commands_update_self() {
    local BRANCH=${1-}
    local Notice=${2-}
    shift 2

    pushd "${SCRIPTPATH}" &> /dev/null || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}push \"${SCRIPTPATH}\""
    local QUIET=''
    if [[ -z ${VERBOSE-} ]]; then
        QUIET='--quiet'
    fi
    notice "${Notice}"
    cd "${SCRIPTPATH}" || fatal "Failed to change directory.\nFailing command: ${C["FailingCommand"]}cd \"${SCRIPTPATH}\""
    info "Setting file ownership on current repository files"
    sudo chown -R "$(id -u)":"$(id -g)" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "$(id -u)":"$(id -g)" "${SCRIPTPATH}" > /dev/null 2>&1 || true
    git ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" > /dev/null 2>&1 || true

    info "Fetching recent changes from git."
    eval git fetch ${QUIET-} --all --prune || fatal "Failed to fetch recent changes from git.\nFailing command: ${C["FailingCommand"]}git fetch ${QUIET-} --all --prune"
    if [[ ${CI-} != true ]]; then
        eval git switch ${QUIET-} --force "${BRANCH}" || fatal "Failed to switch to github branch '${C["Branch"]}${BRANCH}${NC}'.\nFailing command: ${C["FailingCommand"]}git switch ${QUIET-} --force \"${BRANCH}\""
        eval git reset ${QUIET-} --hard origin/"${BRANCH}" || fatal "Failed to reset to branch '${C["Branch"]}origin/${BRANCH}${NC}'.\nFailing command: ${C["FailingCommand"]}git reset ${QUIET-} --hard origin/\"${BRANCH}\""
        info "Pulling recent changes from git."
        eval git pull ${QUIET-} || fatal "Failed to pull recent changes from git.\nFailing command: ${C["FailingCommand"]}git pull ${QUIET-}"
    fi
    info "Cleaning up unnecessary files and optimizing the local repository."
    eval git gc ${QUIET-} || true
    info "Setting file ownership on new repository files"
    git ls-tree -rt --name-only "${BRANCH}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" > /dev/null 2>&1 || true
    sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" > /dev/null 2>&1 || true
    sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}" > /dev/null 2>&1 || true
    notice "Updated ${APPLICATION_NAME} to '${C["Version"]}$(ds_version)${NC}'"
    popd &> /dev/null
    if [[ -z $* ]]; then
        exec bash "${SCRIPTNAME}" -e
    else
        exec "$@"
    fi
}

test_update_self() {
    warn "CI does not test update_self."
    #@run_script 'update_self' "${COMMIT_SHA-}"
}
