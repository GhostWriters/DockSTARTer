#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
	local Branch CurrentVersion RemoteVersion
	Branch=${1-}
	shift || true
	if [[ ${Branch-} == "${APPLICATION_LEGACY_BRANCH}" ]] && ds_branch_exists "${APPLICATION_DEFAULT_BRANCH}"; then
		warn "Updating to branch '${C["Branch"]}${APPLICATION_DEFAULT_BRANCH}${NC}' instead of '${C["Branch"]}${APPLICATION_LEGACY_BRANCH}${NC}'."
		Branch="${APPLICATION_DEFAULT_BRANCH}"
	fi

	local Title="Update ${C["ApplicationName"]-}${APPLICATION_NAME}${NC}"
	local Question YesNotice NoNotice

	pushd "${SCRIPTPATH}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}push \"${SCRIPTPATH}\""

	if [[ -z ${Branch-} ]]; then
		Branch="$(ds_branch)"
		if ds_tag_exists "${Branch-}"; then
			Branch="$(ds_best_branch)"
		fi
		if [[ -z ${Branch-} ]]; then
			error "You need to specify a branch to update to."
			return 1
		fi
	fi

	CurrentVersion="$(ds_version)"
	RemoteVersion="$(ds_version "${Branch}")"
	if [[ ${CurrentVersion-} == "${RemoteVersion-}" ]]; then
		if [[ -n ${FORCE-} ]]; then
			Question="Would you like to forcefully re-apply ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} update '${C["Version"]}${CurrentVersion}${NC}'?"
			NoNotice="${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} will not be updated."
			YesNotice="Forcefully re-applying ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} update '${C["Version"]}${RemoteVersion}${NC}'"
		fi
	else
		Question="Would you like to update ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}' now?"
		NoNotice="${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} will not be updated."
		YesNotice="Updating ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
	fi
	popd &> /dev/null

	if ! ds_branch_exists "${Branch}" && ! ds_tag_exists "${Branch}" && ! ds_commit_exists "${Branch}"; then
		local ErrorMessage="${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} ref '${C["Branch"]}${Branch}${NC}' does not exist on origin."
		if use_dialog_box; then
			error "${ErrorMessage}" |&
				dialog_pipe "${DC["TitleError"]-}${Title}" "${DC["CommandLine"]-} ${APPLICATION_COMMAND} --update $*"
		else
			error "${ErrorMessage}"
		fi
		return 1
	fi

	if [[ -z ${FORCE-} && ${CurrentVersion} == "${RemoteVersion}" ]]; then
		if use_dialog_box; then
			{
				notice "${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} is already up to date on branch '${C["Branch"]}${Branch}${NC}'."
				notice "Current version is '${C["Version"]}${CurrentVersion}${NC}'"
			} |& dialog_pipe "${DC["TitleWarning"]-}${Title}" "${DC[CommandLine]-} ${APPLICATION_COMMAND} --update $*"
		else
			notice "${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} is already up to date on branch '${C["Branch"]}${Branch}${NC}'."
			notice "Current version is '${C["Version"]}${CurrentVersion}${NC}'"
		fi
		return 0
	fi

	if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		if use_dialog_box; then
			notice "${NoNotice}" |& dialog_pipe "${DC["TitleError"]-}${Title}" "${NoNotice}"
		else
			notice "${NoNotice}"
		fi
		return 1
	fi

	if use_dialog_box; then
		YesNotice="$(strip_ansi_colors "${YesNotice}")"
		commands_update_self "${Branch}" "${YesNotice}" "$@" |&
			dialog_pipe "${DC["TitleSuccess"]-}${Title}" "${YesNotice}\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --update $*"
	else
		commands_update_self "${Branch}" "${YesNotice}" "$@"
	fi
}

commands_update_self() {
	local Branch=${1-}
	local Notice=${2-}
	shift 2

	pushd "${SCRIPTPATH}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}push \"${SCRIPTPATH}\""
	local QUIET=''
	if [[ -z ${VERBOSE-} ]]; then
		QUIET='--quiet'
	fi
	notice "${Notice}"
	cd "${SCRIPTPATH}" ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}cd \"${SCRIPTPATH}\""
	info "Setting file ownership on current repository files"
	sudo chown -R "$(id -u)":"$(id -g)" "${SCRIPTPATH}/.git" &> /dev/null || true
	sudo chown "$(id -u)":"$(id -g)" "${SCRIPTPATH}" &> /dev/null || true
	git ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" &> /dev/null || true

	info "Fetching recent changes from git."
	eval git fetch ${QUIET-} --all --prune ||
		fatal \
			"Failed to fetch recent changes from git." \
			"Failing command: ${C["FailingCommand"]}git fetch ${QUIET-} --all --prune"
	if [[ ${CI-} != true ]]; then
		eval git checkout ${QUIET-} --force "${Branch}" ||
			fatal \
				"Failed to switch to github ref '${C["Branch"]}${Branch}${NC}'." \
				"Failing command: ${C["FailingCommand"]}git checkout ${QUIET-} --force \"${Branch}\""

		# If it's a branch (not a tag or SHA), perform reset and pull
		if git ls-remote --exit-code --heads origin "${Branch}" &> /dev/null; then
			eval git reset ${QUIET-} --hard origin/"${Branch}" ||
				fatal \
					"Failed to reset to branch '${C["Branch"]}origin/${Branch}${NC}'." \
					"Failing command: ${C["FailingCommand"]}git reset ${QUIET-} --hard origin/\"${Branch}\""
			info "Pulling recent changes from git."
			eval git pull ${QUIET-} ||
				fatal \
					"Failed to pull recent changes from git." \
					"Failing command: ${C["FailingCommand"]}git pull ${QUIET-}"
		fi
	fi
	info "Cleaning up unnecessary files and optimizing the local repository."
	eval git gc ${QUIET-} || true
	info "Setting file ownership on new repository files"
	git ls-tree -rt --name-only "${Branch}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" &> /dev/null || true
	sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" &> /dev/null || true
	sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}" &> /dev/null || true
	notice "Updated ${APPLICATION_NAME} to '${C["Version"]}$(ds_version)${NC}'"
	popd &> /dev/null

	# run_script 'reset_needs' # Add script lines in-line below
	if [[ -d ${TIMESTAMPS_FOLDER:?} ]]; then
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
		rm -rf "${TIMESTAMPS_FOLDER:?}" &> /dev/null || true
	fi
	if [[ -d ${TEMP_FOLDER:?} ]]; then
		run_script 'set_permissions' "${TEMP_FOLDER:?}"
		rm -rf "${TEMP_FOLDER:?}" &> /dev/null || true
	fi

	if [[ -z $* ]]; then
		exec bash "${SCRIPTNAME}" -e
	else
		exec bash "${SCRIPTNAME}" "$@"
	fi
	exit
}

test_update_self() {
	warn "CI does not test update_self."
	#@run_script 'update_self' "${COMMIT_SHA-}"
}
