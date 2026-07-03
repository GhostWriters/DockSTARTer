#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

git_fetch() {
	local GitPath=${1}
	local ForceRefresh=${2-false}
	# Git touches FETCH_HEAD after each `git fetch`, so we use it to
	# limit fetches to 1 per day per repo (unless forced).
	if [[ -n ${FORCE-} ]] || $ForceRefresh || [ -z "$(find "${GitPath}/.git/FETCH_HEAD" -mtime -1 2> /dev/null)" ]; then
		git -C "${GitPath}" fetch --quiet --tags &> /dev/null || true
	fi
}

git_branch_into() {
	local -n _gbi_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local DefaultBranch=${3-}
	local LegacyBranch=${4-}
	git_fetch "${GitPath}"
	local _gbi_val_
	_gbi_val_=$(git -C "${GitPath}" symbolic-ref --short HEAD 2> /dev/null || git -C "${GitPath}" describe --tags --exact-match 2> /dev/null) || true
	if [[ -z ${_gbi_val_} ]]; then
		git_best_branch_into _gbi_val_ "${GitPath}" "${DefaultBranch-}" "${LegacyBranch-}"
	fi
	_gbi_out_="${_gbi_val_}"
}

git_branch() {
	local result
	git_branch_into result "$@"
	echo "${result}"
}

git_branch_exists() {
	local GitPath=${1}
	local Branch=${2-}
	git -C "${GitPath}" ls-remote --quiet --exit-code --heads origin "${Branch}" &> /dev/null
	local result=$?
	return ${result}
}

git_tag_exists() {
	local GitPath=${1}
	local Tag=${2-}
	git -C "${GitPath}" ls-remote --quiet --exit-code --tags origin "${Tag}" &> /dev/null
	local result=$?
	return ${result}
}

git_commit_exists() {
	local GitPath=${1}
	local Commit=${2-}
	[[ ${Commit} =~ ^[0-9a-fA-F]{7,40}$ ]] || return 1
	git -C "${GitPath}" rev-parse --quiet --verify "${Commit}^{commit}" &> /dev/null
	local result=$?
	return ${result}
}

git_version_into() {
	local -n _gvi_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local CheckBranch=${3-}
	local commitish Branch

	if [[ -n ${CheckBranch-} ]]; then
		if git -C "${GitPath}" show-ref --quiet --tags "${CheckBranch}" &> /dev/null; then
			commitish="${CheckBranch}"
			Branch="${CheckBranch}"
		elif git -C "${GitPath}" ls-remote --quiet --exit-code --heads origin "${CheckBranch}" &> /dev/null; then
			commitish="origin/${CheckBranch}"
			Branch="${CheckBranch}"
		elif git -C "${GitPath}" rev-parse --quiet --verify "${CheckBranch}^{commit}" &> /dev/null; then
			commitish="${CheckBranch}"
			git_best_branch_into Branch "${GitPath}"
			if [[ -z ${Branch-} ]]; then
				Branch="${CheckBranch}"
			fi
		else
			commitish="origin/${CheckBranch}"
			Branch="${CheckBranch}"
		fi
	else
		commitish='HEAD'
		if [[ ${GitPath} == "${SCRIPTPATH}" ]]; then
			ds_branch_into Branch
		elif [[ ${GitPath} == "${TEMPLATES_PARENT_FOLDER}" ]]; then
			templates_branch_into Branch
		else
			git_branch_into Branch "${GitPath}"
		fi
	fi

	local VersionString=''
	if [[ -z ${CheckBranch-} ]] || git_branch_exists "${GitPath}" "${Branch}" || git_tag_exists "${GitPath}" "${Branch}" || git_commit_exists "${GitPath}" "${Branch}"; then
		VersionString="$(git -C "${GitPath}" describe --tags --exact-match "${commitish}" 2> /dev/null || true)"
		if [[ -n ${VersionString-} ]]; then
			if [[ ${VersionString} != "${Branch}" ]] && [[ ${Branch} != "main" || ${VersionString} == "main" ]]; then
				VersionString="${Branch} ${VersionString}"
			fi
		else
			local CommitHash
			CommitHash="$(git -C "${GitPath}" rev-parse --short "${commitish}" 2> /dev/null || true)"
			if [[ ${CommitHash} == "${Branch}" ]]; then
				VersionString="commit ${CommitHash}"
			else
				VersionString="${Branch} commit ${CommitHash}"
			fi
		fi
	fi
	_gvi_out_="${VersionString}"
}

git_version() {
	local result
	git_version_into result "$@"
	echo "${result}"
}

git_resolve_update_target_into() {
	# Resolves the branch/tag name that should actually be checked out for
	# an update, applying a release policy when the caller auto-detected
	# (didn't explicitly request) the default branch: CI (e.g. renovate)
	# commits land on the default branch between releases, so its literal
	# tip is frequently not the commit anyone actually meant to update to.
	# Restrict to the latest tag reachable from the default branch's
	# history instead. Falls back to the default branch's tip if no
	# reachable tag exists yet (e.g. before any release).
	#
	# Everything downstream (git_version_into, git checkout) already treats
	# a tag name exactly like a branch name, so callers just use this
	# function's output as "Branch" for the rest of their update flow --
	# no other logic needs to change.
	#
	# If CurrentBranch (the branch actually checked out right now) equals
	# the resolved default-branch target, and the latest reachable tag is
	# an ancestor of (or equal to) current HEAD, this returns CurrentBranch
	# unchanged instead of the tag -- i.e. "no update available" rather than
	# incorrectly offering to move backward to an older tag. This check is
	# skipped when switching branches (CurrentBranch != RequestedBranch):
	# a different branch happening to descend from the default branch's
	# latest tag must never block the switch itself.
	#
	# Only an explicit tag/commit request (WasExplicit=true) bypasses this
	# policy entirely and is returned unchanged.
	local -n _grti_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local DefaultBranch=${3}
	local RequestedBranch=${4}
	local CurrentBranch=${5-}
	local WasExplicit=${6-false}

	if $WasExplicit || [[ ${RequestedBranch} != "${DefaultBranch}" ]]; then
		_grti_out_="${RequestedBranch}"
		return
	fi

	local LatestTag
	LatestTag=$(git -C "${GitPath}" tag --merged "origin/${DefaultBranch}" 2> /dev/null | sort -V | tail -1) || true

	if [[ -z ${LatestTag} ]]; then
		# No reachable tag yet -- fall back to the default branch's tip.
		_grti_out_="${RequestedBranch}"
		return
	fi

	if [[ ${CurrentBranch} == "${RequestedBranch}" ]] && git -C "${GitPath}" merge-base --is-ancestor "${LatestTag}" HEAD 2> /dev/null; then
		# Current HEAD is already at or ahead of the latest tag and we're
		# staying on the same branch -- report no update by returning the
		# current branch name unchanged.
		_grti_out_="${CurrentBranch}"
		return
	fi

	_grti_out_="${LatestTag}"
}

git_resolve_update_target() {
	local result
	git_resolve_update_target_into result "$@"
	echo "${result}"
}

git_update_available() {
	local GitPath=${1}
	local CurrentRef=${2-}
	local TargetRef=${3-}
	git_fetch "${GitPath}"
	local -i result=0
	local Current Remote
	Current=$(git -C "${GitPath}" rev-parse HEAD 2> /dev/null || true)

	if [[ -n ${CurrentRef} ]]; then
		if [[ -z ${TargetRef-} ]]; then
			TargetRef="${CurrentRef}"
		fi

		# If CurrentRef is a tag, we compare against TargetRef (usually a branch)
		# Even if it's a tag, we compare the current hash against the target branch/ref hash
		Remote=$(git -C "${GitPath}" rev-parse "origin/${TargetRef}" 2> /dev/null || true)
		[[ ${Current} != "${Remote}" ]]
		result=$?
	else
		# Default behavior: compare HEAD to upstream
		Remote=$(git -C "${GitPath}" rev-parse '@{u}' 2> /dev/null || true)
		if [[ -n ${Remote} ]]; then
			[[ ${Current} != "${Remote}" ]]
			result=$?
		else
			# No upstream (detached), check against origin/main as fallback
			Remote=$(git -C "${GitPath}" rev-parse "origin/main" 2> /dev/null || true)
			[[ ${Current} != "${Remote}" ]]
			result=$?
		fi
	fi
	return ${result}
}

ds_fetch() {
	local ForceRefresh=${1-false}
	git_fetch "${SCRIPTPATH}" "${ForceRefresh}"
}

ds_branch_into() {
	local -n _dbi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_branch_into _dbi_out_ "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH-}" "${APPLICATION_LEGACY_BRANCH-}"
}

ds_branch() {
	local result
	ds_branch_into result "$@"
	echo "${result}"
}

ds_branch_exists() {
	local Branch=${1-}
	git_branch_exists "${SCRIPTPATH}" "${Branch-}"
}

ds_tag_exists() {
	local Tag=${1-}
	git_tag_exists "${SCRIPTPATH}" "${Tag-}"
}

ds_commit_exists() {
	local Commit=${1-}
	git_commit_exists "${SCRIPTPATH}" "${Commit-}"
}

ds_ref_exists() {
	local Ref=${1-}
	ds_branch_exists "${Ref}" || ds_tag_exists "${Ref}" || ds_commit_exists "${Ref}"
}

ds_version_into() {
	local -n _dvi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_version_into _dvi_out_ "${SCRIPTPATH}" "${2-}"
}

ds_version() {
	local result
	ds_version_into result "$@"
	echo "${result}"
}

ds_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	git_update_available "${SCRIPTPATH}" "${CurrentRef-}" "${TargetRef-}"
}

templates_fetch() {
	local ForceRefresh=${1-false}
	git_fetch "${TEMPLATES_PARENT_FOLDER}" "${ForceRefresh}"
}

templates_branch_into() {
	local -n _tbi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_branch_into _tbi_out_ "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH-}"
}

templates_branch() {
	local result
	templates_branch_into result "$@"
	echo "${result}"
}

templates_branch_exists() {
	local Branch=${1-}
	git_branch_exists "${TEMPLATES_PARENT_FOLDER}" "${Branch-}"
}

templates_tag_exists() {
	local Tag=${1-}
	git_tag_exists "${TEMPLATES_PARENT_FOLDER}" "${Tag-}"
}

templates_commit_exists() {
	local Commit=${1-}
	git_commit_exists "${TEMPLATES_PARENT_FOLDER}" "${Commit-}"
}

templates_ref_exists() {
	local Ref=${1-}
	templates_branch_exists "${Ref}" || templates_tag_exists "${Ref}" || templates_commit_exists "${Ref}"
}

templates_version_into() {
	local -n _tvi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_version_into _tvi_out_ "${TEMPLATES_PARENT_FOLDER}" "${2-}"
}

templates_version() {
	local result
	templates_version_into result "$@"
	echo "${result}"
}

templates_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	git_update_available "${TEMPLATES_PARENT_FOLDER}" "${CurrentRef-}" "${TargetRef-}"
}

ds_switch_branch() {
	local CurrentBranch
	ds_branch_into CurrentBranch
	if [[ ${CurrentBranch} == "${APPLICATION_LEGACY_BRANCH}" ]] && ds_branch_exists "${APPLICATION_DEFAULT_BRANCH}"; then
		export FORCE=true
		export PROMPT="CLI"
		notice \
			"Automatically switching from {{|ApplicationName|}}${APPLICATION_NAME}{{[-]}} branch '{{|Branch|}}${APPLICATION_LEGACY_BRANCH}{{[-]}}' to '{{|Branch|}}${APPLICATION_DEFAULT_BRANCH}{{[-]}}'."
		run_script 'update_self' "${APPLICATION_DEFAULT_BRANCH}" "${ARGS[@]}"
		exit
	fi
}

git_best_branch_into() {
	local -n _gbbi_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local DefaultBranch=${3-}
	local LegacyBranch=${4-}
	local -a Branches=()
	readarray -t Branches < <(git -C "${GitPath}" branch -r --contains HEAD 2> /dev/null | sed 's/^[[:space:]]*origin\///' | grep -v 'HEAD ->')
	local BestBranch=""
	if [[ ${#Branches[@]} -gt 0 ]]; then
		# 1. Prioritize Default Branch
		for b in "${Branches[@]}"; do
			if [[ ${b} == "${DefaultBranch}" ]]; then
				BestBranch="${DefaultBranch}"
				break
			fi
		done
		# 2. Prioritize Legacy Branch if Default not found
		if [[ -z ${BestBranch} && -n ${LegacyBranch} ]]; then
			for b in "${Branches[@]}"; do
				if [[ ${b} == "${LegacyBranch}" ]]; then
					BestBranch="${LegacyBranch}"
					break
				fi
			done
		fi
		# 3. If only one branch total, use it
		if [[ -z ${BestBranch} && ${#Branches[@]} -eq 1 ]]; then
			BestBranch="${Branches[0]}"
		fi
	fi

	# 4. If we ended up with the Legacy Branch but the Default Branch exists, force use of Default Branch
	if [[ ${BestBranch} == "${LegacyBranch}" ]] && [[ -n ${DefaultBranch} ]]; then
		if git -C "${GitPath}" show-ref --quiet --verify "refs/remotes/origin/${DefaultBranch}"; then
			BestBranch="${DefaultBranch}"
		fi
	fi

	# 5. Fallback to Default Branch
	if [[ -z ${BestBranch} ]]; then
		BestBranch="${DefaultBranch}"
	fi
	_gbbi_out_="${BestBranch}"
}

git_best_branch() {
	local result
	git_best_branch_into result "$@"
	echo "${result}"
}

ds_best_branch_into() {
	local -n _dbbi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_best_branch_into _dbbi_out_ "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH-}" "${APPLICATION_LEGACY_BRANCH-}"
}

ds_best_branch() {
	local result
	ds_best_branch_into result "$@"
	echo "${result}"
}

templates_best_branch_into() {
	local -n _tbbi_out_="${1}"
	assert_nameref_is_string "${1}"
	git_best_branch_into _tbbi_out_ "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH-}"
}

templates_best_branch() {
	local result
	templates_best_branch_into result "$@"
	echo "${result}"
}
