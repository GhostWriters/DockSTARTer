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
			Question="Would you like to forcefully re-apply {{|ApplicationName|}}${TargetName}{{[-]}} update '{{|Version|}}${CurrentVersion}{{[-]}}'?"
			NoNotice="{{|ApplicationName|}}${TargetName}{{[-]}} will not be updated."
			YesNotice="Forcefully re-applying {{|ApplicationName|}}${TargetName}{{[-]}} update '{{|Version|}}${RemoteVersion}{{[-]}}'"
		fi
	else
		Question="Would you like to update {{|ApplicationName|}}${TargetName}{{[-]}} from '{{|Version|}}${CurrentVersion}{{[-]}}' to '{{|Version|}}${RemoteVersion}{{[-]}}' now?"
		NoNotice="{{|ApplicationName|}}${TargetName}{{[-]}} will not be updated."
		YesNotice="Updating {{|ApplicationName|}}${TargetName}{{[-]}} from '{{|Version|}}${CurrentVersion}{{[-]}}' to '{{|Version|}}${RemoteVersion}{{[-]}}'"
	fi

	if ! templates_branch_exists "${Branch}" && ! templates_tag_exists "${Branch}" && ! templates_commit_exists "${Branch}"; then
		local ErrorMessage="{{|ApplicationName|}}${TargetName}{{[-]}} ref '{{|Branch|}}${Branch}{{[-]}}' does not exist on origin."
		if use_dialog_box; then
			error "${ErrorMessage}" |&
				dialog_pipe "{{|TitleError|}}${Title}" "{{|CommandLine|}} ${APPLICATION_COMMAND} --update $*"
		else
			error "${ErrorMessage}"
		fi
		return 1
	fi

	if [[ -z ${FORCE-} && ${CurrentVersion} == "${RemoteVersion}" ]]; then
		if use_dialog_box; then
			{
				{
					notice \
						"{{|ApplicationName|}}${TargetName}{{[-]}} is already up to date on branch '{{|Branch|}}${Branch}{{[-]}}'." \
						"Current version is '{{|Version|}}${CurrentVersion}{{[-]}}'"
				} || true
			} |& dialog_pipe "{{|TitleWarning|}}${Title}" "{{|CommandLine|}} ${APPLICATION_COMMAND} --update-templates $*"
		else
			notice \
				"{{|ApplicationName|}}${TargetName}{{[-]}} is already up to date on branch '{{|Branch|}}${Branch}{{[-]}}'." \
				"Current version is '{{|Version|}}${CurrentVersion}{{[-]}}'"
		fi
		return 0
	fi

	if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		if use_dialog_box; then
			{ notice "${NoNotice}" || true; } |& dialog_pipe "{{|TitleError|}}${Title}" "${NoNotice}"
		else
			notice "${NoNotice}"
		fi
		return 1
	fi

	if use_dialog_box; then
		{ commands_update_templates "${Branch}" "${YesNotice}" "$@" || true; } |&
			dialog_pipe "{{|TitleSuccess|}}${Title}" "${YesNotice}\n{{|CommandLine|}} ${APPLICATION_COMMAND} --update $*"
	else
		commands_update_templates "${Branch}" "${YesNotice}" "$@"
	fi
}

commands_update_templates() {
	local Branch=${1-}
	local Notice=${2-}
	shift 2

	notice "${Notice}"
	info "Setting file ownership on current repository files"
	sudo chown -R "$(id -u)":"$(id -g)" "${TEMPLATES_PARENT_FOLDER}/.git" &> /dev/null || true
	sudo chown "$(id -u)":"$(id -g)" "${TEMPLATES_PARENT_FOLDER}" &> /dev/null || true
	git -C "${TEMPLATES_PARENT_FOLDER}" ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" &> /dev/null || true

	info "Fetching recent changes from git."
	RunAndLog info "git:info" \
		fatal "Failed to fetch recent changes from git." \
		git -C "${TEMPLATES_PARENT_FOLDER}" fetch --all --prune -v
	if [[ ${CI-} != true ]]; then
		RunAndLog info "git:info" \
			fatal "Failed to switch to github ref '{{|Branch|}}${Branch}{{[-]}}'." \
			git -C "${TEMPLATES_PARENT_FOLDER}" checkout --force "${Branch}"

		# If it's a branch (not a tag or SHA), perform reset and pull
		if git -C "${TEMPLATES_PARENT_FOLDER}" ls-remote --exit-code --heads origin "${Branch}" &> /dev/null; then
			RunAndLog info "git:info" \
				fatal "Failed to reset to branch '{{|Branch|}}origin/${Branch}{{[-]}}'." \
				git -C "${TEMPLATES_PARENT_FOLDER}" reset --hard origin/"${Branch}"
			info "Pulling recent changes from git."
			RunAndLog info "git:info" \
				fatal "Failed to pull recent changes from git." \
				git -C "${TEMPLATES_PARENT_FOLDER}" pull
		fi
	fi
	info "Cleaning up unnecessary files and optimizing the local repository."
	RunAndLog info "git:info" \
		"" "" \
		git -C "${TEMPLATES_PARENT_FOLDER}" gc || true
	info "Setting file ownership on new repository files"
	git -C "${TEMPLATES_PARENT_FOLDER}" ls-tree -rt --name-only "${Branch}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" &> /dev/null || true
	sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${TEMPLATES_PARENT_FOLDER}/.git" &> /dev/null || true
	sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${TEMPLATES_PARENT_FOLDER}" &> /dev/null || true
	notice "Updated ${TargetName} to '{{|Version|}}$(templates_version){{[-]}}'"

	# run_script 'reset_needs' (DELETED in favor of granular detection)
}

test_update_templates() {
	warn "CI does not test update_templates."
	#@run_script 'update_templates' "${COMMIT_SHA-}"
}
