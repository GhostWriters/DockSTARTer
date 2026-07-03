#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

update_self() {
	local Branch CurrentVersion RemoteVersion
	Branch=${1-}
	local WasExplicit=true
	[[ -z ${Branch} ]] && WasExplicit=false
	shift || true
	ds_fetch true
	if [[ ${Branch-} == "${APPLICATION_LEGACY_BRANCH}" ]] && ds_branch_exists "${APPLICATION_DEFAULT_BRANCH}"; then
		warn "Updating to branch '{{|Branch|}}${APPLICATION_DEFAULT_BRANCH}{{[-]}}' instead of '{{|Branch|}}${APPLICATION_LEGACY_BRANCH}{{[-]}}'."
		Branch="${APPLICATION_DEFAULT_BRANCH}"
	fi

	local Title="Update ${APPLICATION_NAME}"
	local Question YesNotice NoNotice

	local CurrentBranch
	ds_branch_into CurrentBranch

	if [[ -z ${Branch-} ]]; then
		Branch="${CurrentBranch}"
		if ds_tag_exists "${Branch-}"; then
			ds_best_branch_into Branch
		fi
		if [[ -z ${Branch-} ]]; then
			error "You need to specify a branch to update to."
			return 1
		fi
	fi

	# On the default branch (unless a specific tag/commit was explicitly
	# requested), restrict to the latest tagged release instead of the
	# branch's literal tip -- see git_resolve_update_target_into's doc
	# comment for why. Downstream logic (version lookup, checkout) is
	# unchanged: it already treats a tag name exactly like a branch name.
	git_resolve_update_target_into Branch "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH}" "${Branch}" "${CurrentBranch}" "${WasExplicit}"

	ds_version_into CurrentVersion
	ds_version_into RemoteVersion "${Branch}"
	if [[ ${CurrentVersion-} == "${RemoteVersion-}" ]]; then
		if [[ -n ${FORCE-} ]]; then
			Question="Would you like to forcefully re-apply {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} update '{{|Version|}}${CurrentVersion}{{[-]}}'?"
			NoNotice="{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} will not be updated."
			YesNotice="Forcefully re-applying {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} update '{{|Version|}}${RemoteVersion}{{[-]}}'"
		fi
	else
		Question="Would you like to update {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} from '{{|Version|}}${CurrentVersion}{{[-]}}' to '{{|Version|}}${RemoteVersion}{{[-]}}' now?"
		NoNotice="{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} will not be updated."
		YesNotice="Updating {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} from '{{|Version|}}${CurrentVersion}{{[-]}}' to '{{|Version|}}${RemoteVersion}{{[-]}}'"
	fi

	local CommandLineText
	CommandLineText="$(printf '%q ' "${APPLICATION_COMMAND}" "--update" "$@" | xargs)"
	if ! ds_branch_exists "${Branch}" && ! ds_tag_exists "${Branch}" && ! ds_commit_exists "${Branch}"; then
		local ErrorMessage="{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} ref '{{|Branch|}}${Branch}{{[-]}}' does not exist on origin."
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleError|}}${Title}" "{{|CommandLine|}} ${CommandLineText}"
		error "${ErrorMessage}" >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
		return 1
	fi

	if [[ -z ${FORCE-} && ${CurrentVersion} == "${RemoteVersion}" ]]; then
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleWarning|}}${Title}" "{{|CommandLine|}} ${CommandLineText}"
		{
			notice \
				"{{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} is already up to date on branch '{{|Branch|}}${Branch}{{[-]}}'." \
				"Current version is '{{|Version|}}${CurrentVersion}{{[-]}}'" || true
		} >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
		return 0
	fi

	if ! run_script 'question_prompt' Y "${Question}" "${Title}" "${ASSUMEYES:+Y}"; then
		#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
		local -i PipeFD PipePID
		tui_pipe_open PipeFD PipePID "{{|TitleError|}}${Title}" "${NoNotice}"
		{ notice "${NoNotice}" || true; } >&${PipeFD} 2>&1
		tui_pipe_close PipeFD PipePID
		return 1
	fi

	#shellcheck disable=SC2034 # (warning): PipePID is passed by name to tui_pipe_open/close via nameref and appears unused to shellcheck.
	local -i PipeFD PipePID
	tui_pipe_open PipeFD PipePID "{{|TitleSuccess|}}${Title}" "${YesNotice}\n{{|CommandLine|}} ${CommandLineText}"
	{ commands_update_self_logic "${Branch}" "${YesNotice}" "$@" || true; } >&${PipeFD} 2>&1
	tui_pipe_close PipeFD PipePID

	local -a CommandArray
	if [[ -z $* ]]; then
		CommandArray=(bash "${SCRIPTNAME}" "-e")
	else
		CommandArray=(bash "${SCRIPTNAME}" "$@")
	fi
	local CommandNotice
	CommandNotice="exec $(printf '%q ' "${CommandArray[@]}" | xargs)"
	notice "Running: {{|RunningCommand|}}${CommandNotice}{{[-]}}"
	exec "${CommandArray[@]}"
	exit
}

commands_update_self_logic() {
	local Branch=${1-}
	local Notice=${2-}
	shift 2

	notice "${Notice}"

	info "Setting file ownership on current repository files"
	sudo chown -R "$(id -u)":"$(id -g)" "${SCRIPTPATH}/.git" &> /dev/null || true
	sudo chown "$(id -u)":"$(id -g)" "${SCRIPTPATH}" &> /dev/null || true
	git -C "${SCRIPTPATH}" ls-tree -rt --name-only HEAD | xargs sudo chown "$(id -u)":"$(id -g)" &> /dev/null || true

	info "Fetching recent changes from git."
	RunAndLog info "git:info" \
		fatal "Failed to fetch recent changes from git." \
		git -C "${SCRIPTPATH}" fetch --all --prune -v
	if [[ ${CI-} != true ]]; then
		RunAndLog info "git:info" \
			fatal "Failed to switch to github ref '{{|Branch|}}${Branch}{{[-]}}'." \
			git -C "${SCRIPTPATH}" checkout --force "${Branch}"

		# If it's a branch (not a tag or SHA), perform reset and pull
		if git -C "${SCRIPTPATH}" ls-remote --exit-code --heads origin "${Branch}" &> /dev/null; then
			RunAndLog info "git:info" \
				fatal "Failed to reset to branch '{{|Branch|}}origin/${Branch}{{[-]}}'." \
				git -C "${SCRIPTPATH}" reset --hard origin/"${Branch}"
			info "Pulling recent changes from git."
			RunAndLog info "git:info" \
				fatal "Failed to pull recent changes from git." \
				git -C "${SCRIPTPATH}" pull
		fi
	fi
	info "Cleaning up unnecessary files and optimizing the local repository."
	RunAndLog info "git:info" \
		"" "" \
		git -C "${SCRIPTPATH}" gc || true
	info "Setting file ownership on new repository files"
	git -C "${SCRIPTPATH}" ls-tree -rt --name-only "${Branch}" | xargs sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" &> /dev/null || true
	sudo chown -R "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}/.git" &> /dev/null || true
	sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${SCRIPTPATH}" &> /dev/null || true
	local UpdatedVersion
	ds_version_into UpdatedVersion
	notice \
		"Updated ${APPLICATION_NAME} to '{{|Version|}}${UpdatedVersion}{{[-]}}'"

	# run_script 'reset_needs' # Add script lines in-line below
	if [[ -d ${TIMESTAMPS_FOLDER:?} ]]; then
		run_script 'set_permissions' "${TIMESTAMPS_FOLDER:?}"
		rm -rf "${TIMESTAMPS_FOLDER:?}" &> /dev/null || true
	fi
	if [[ -d ${TEMP_FOLDER:?} ]]; then
		run_script 'set_permissions' "${TEMP_FOLDER:?}"
		rm -rf "${TEMP_FOLDER:?}" &> /dev/null || true
	fi
}

test_update_self() {
	warn "CI does not test update_self."
	#@run_script 'update_self' "${COMMIT_SHA-}"
}
