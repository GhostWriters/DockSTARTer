#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare TargetName="${TEMPLATES_NAME}"

update_templates() {
	local Branch CurrentVersion RemoteVersion
	Branch=${1-}
	shift || true
	local Title="Update ${TargetName}"
	local Question YesNotice NoNotice

	RunAndLog "" "OutToNull|ErrToNull" \
		fatal "Failed to change directory." \
		pushd "${TEMPLATES_PARENT_FOLDER}"

	if [[ -z ${Branch-} ]]; then
		Branch="$(templates_branch)"
		if templates_tag_exists "${Branch-}"; then
			Branch="$(templates_best_branch)"
		fi
		if [[ -z ${Branch-} ]]; then
			error "You need to specify a branch to update to."
			return 1
		fi
	fi

	CurrentVersion="$(templates_version)"
	RemoteVersion="$(templates_version "${Branch}")"
	if [[ ${CurrentVersion-} == "${RemoteVersion-}" ]]; then
		if [[ -n ${FORCE-} ]]; then
			Question="Would you like to forcefully re-apply ${C["ApplicationName"]-}${TargetName}${NC-} update '${C["Version"]}${CurrentVersion}${NC}'?"
			NoNotice="${C["ApplicationName"]-}${TargetName}${NC-} will not be updated."
			YesNotice="Forcefully re-applying ${C["ApplicationName"]-}${TargetName}${NC-} update '${C["Version"]}${RemoteVersion}${NC}'"
		fi
	else
		Question="Would you like to update ${C["ApplicationName"]-}${TargetName}${NC-} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}' now?"
		NoNotice="${C["ApplicationName"]-}${TargetName}${NC-} will not be updated."
		YesNotice="Updating ${C["ApplicationName"]-}${TargetName}${NC-} from '${C["Version"]}${CurrentVersion}${NC}' to '${C["Version"]}${RemoteVersion}${NC}'"
	fi
	popd &> /dev/null

	if ! templates_branch_exists "${Branch}" && ! templates_tag_exists "${Branch}" && ! templates_commit_exists "${Branch}"; then
		local ErrorMessage="${C["ApplicationName"]-}${TargetName}${NC-} ref '${C["Branch"]}${Branch}${NC}' does not exist on origin."
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
				notice \
					"${C["ApplicationName"]-}${TargetName}${NC-} is already up to date on branch '${C["Branch"]}${Branch}${NC}'." \
					"Current version is '${C["Version"]}${CurrentVersion}${NC}'"
			} |& dialog_pipe "${DC["TitleWarning"]-}${Title}" "${DC[CommandLine]-} ${APPLICATION_COMMAND} --update-templates $*"
		else
			notice \
				"${C["ApplicationName"]-}${TargetName}${NC-} is already up to date on branch '${C["Branch"]}${Branch}${NC}'." \
				"Current version is '${C["Version"]}${CurrentVersion}${NC}'"
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
		commands_update_templates "${Branch}" "${YesNotice}" "$@" |&
			dialog_pipe "${DC["TitleSuccess"]-}${Title}" "${YesNotice}\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --update $*"
	else
		commands_update_templates "${Branch}" "${YesNotice}" "$@"
	fi
}

commands_update_templates() {
	local Branch=${1-}
	local Notice=${2-}
	shift 2

	RunAndLog "" "OutToNull|ErrToNull" \
		fatal "Failed to change directory." \
		pushd "${TEMPLATES_PARENT_FOLDER}"

	notice "${Notice}"
	info "Setting file ownership on current repository files"
	sudo chown -R "$(id -u)":"$(id -g)" "${TEMPLATES_PARENT_FOLDER}/.git" &> /dev/null || true
	sudo chown "$(id -u)":"$(id -g)" "${TEMPLATES_PARENT_FOLDER}" &> /dev/null || true
	git ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" &> /dev/null || true

	info "Fetching recent changes from git."
	RunAndLog info info \
		fatal "Failed to fetch recent changes from git." \
		git fetch --all --prune -v
	if [[ ${CI-} != true ]]; then
		RunAndLog info info \
			fatal "Failed to switch to github ref '${C["Branch"]}${Branch}${NC}'." \
			git checkout --force "${Branch}"

		# If it's a branch (not a tag or SHA), perform reset and pull
		if git ls-remote --exit-code --heads origin "${Branch}" &> /dev/null; then
			RunAndLog info info \
				fatal "Failed to reset to branch '${C["Branch"]}origin/${Branch}${NC}'." \
				git reset --hard origin/"${Branch}"
			info "Pulling recent changes from git."
			RunAndLog info info \
				fatal "Failed to pull recent changes from git." \
				git pull
		fi
	fi
	info "Cleaning up unnecessary files and optimizing the local repository."
	info "$(git gc 2>&1 || true)"
	info "Setting file ownership on new repository files"
	git ls-tree -rt --name-only "${Branch}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" &> /dev/null || true
	sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${TEMPLATES_PARENT_FOLDER}/.git" &> /dev/null || true
	sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${TEMPLATES_PARENT_FOLDER}" &> /dev/null || true
	notice "Updated ${TargetName} to '${C["Version"]}$(templates_version)${NC}'"
	popd &> /dev/null

	run_script 'reset_needs' # Add script lines in-line below
}

test_update_templates() {
	warn "CI does not test update_templates."
	#@run_script 'update_templates' "${COMMIT_SHA-}"
}
