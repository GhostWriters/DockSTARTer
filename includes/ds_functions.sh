#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

git_fetch() {
	local GitPath=${1}
	local ForceRefresh=${2-false}

	if [[ -n ${FORCE-} ]] || $ForceRefresh; then
		git -C "${GitPath}" fetch --quiet --tags &> /dev/null || true
		return
	fi

	# Cheap pre-check: compare the current branch's remote-tracking hash and
	# the remote's tag count against what's already local, and skip the full
	# fetch only when both match. Tags need their own check because a new
	# tag can point at a commit that's already the local tip -- a branch-
	# hash-only comparison would miss that release entirely.
	local CurrentBranch
	CurrentBranch=$(git -C "${GitPath}" symbolic-ref --short HEAD 2> /dev/null) || true
	if [[ -n ${CurrentBranch} ]]; then
		local RemoteHash LocalHash
		RemoteHash=$(git -C "${GitPath}" ls-remote --quiet origin "refs/heads/${CurrentBranch}" 2> /dev/null | cut -f1) || true
		LocalHash=$(git -C "${GitPath}" rev-parse --quiet --verify "refs/remotes/origin/${CurrentBranch}" 2> /dev/null) || true
		if [[ -n ${RemoteHash} && ${RemoteHash} == "${LocalHash}" ]]; then
			local RemoteTagCount LocalTagCount
			RemoteTagCount=$(git -C "${GitPath}" ls-remote --quiet --tags origin 2> /dev/null | grep -vc '\^{}') || true
			LocalTagCount=$(git -C "${GitPath}" tag 2> /dev/null | wc -l) || true
			if [[ ${RemoteTagCount} == "${LocalTagCount}" ]]; then
				return
			fi
		fi
	fi

	git -C "${GitPath}" fetch --quiet --tags &> /dev/null || true
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

git_latest_reachable_tag_into() {
	# Returns the most recently created tag (by tag creation date, not tag
	# name string) reachable from DefaultBranch's history on origin. Empty
	# if no tag is reachable yet.
	#
	# Sort by actual tag creation date (--sort=-creatordate), not the tag
	# name string (sort -V): this repo has switched tag-naming schemes over
	# time (e.g. v2026.01.19-1 -> v1.20260628.1), and comparing differently-
	# shaped version strings against each other picks the wrong "latest" --
	# creation date is immune to that since it doesn't depend on the name.
	local -n _glrti_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local DefaultBranch=${3}

	_glrti_out_=$(git -C "${GitPath}" tag --merged "origin/${DefaultBranch}" --sort=-creatordate 2> /dev/null | head -1) || true
}

git_latest_reachable_tag() {
	local result
	git_latest_reachable_tag_into result "$@"
	echo "${result}"
}

git_resolve_update_target_into() {
	# Resolves the branch/tag name that should actually be checked out for
	# an update, applying a release policy whenever the resolved branch is
	# the default branch: CI (e.g. renovate) commits land on the default
	# branch between releases, so its literal tip is frequently not the
	# commit anyone actually meant to update to. Restrict to the latest tag
	# reachable from the default branch's history instead. Falls back to
	# the default branch's tip if no reachable tag exists yet (e.g. before
	# any release).
	#
	# This applies whether RequestedBranch reached "the default branch"
	# via auto-detection or because the caller typed the branch name
	# explicitly (e.g. `ds -u "" main`) -- naming the branch is "pick which
	# branch to track", not "opt out of the release policy". Only an
	# explicit literal tag name or commit hash bypasses this, and those
	# naturally never equal DefaultBranch's name.
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
	local -n _grti_out_="${1}"
	assert_nameref_is_string "${1}"
	local GitPath=${2}
	local DefaultBranch=${3}
	local RequestedBranch=${4}
	local CurrentBranch=${5-}

	if [[ ${RequestedBranch} != "${DefaultBranch}" ]]; then
		_grti_out_="${RequestedBranch}"
		return
	fi

	local LatestTag
	git_latest_reachable_tag_into LatestTag "${GitPath}" "${DefaultBranch}"

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

		# TargetRef can be a tag (e.g. the latest-release policy in
		# git_resolve_update_target_into resolving to a tag name) or a
		# branch -- tags aren't under refs/remotes/origin/, so try TargetRef
		# as a tag first and fall back to origin/TargetRef as a branch.
		Remote=$(git -C "${GitPath}" rev-parse --quiet --verify "refs/tags/${TargetRef}" 2> /dev/null) || true
		if [[ -z ${Remote} ]]; then
			Remote=$(git -C "${GitPath}" rev-parse "origin/${TargetRef}" 2> /dev/null || true)
		fi
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

ds_resolve_update_branch_into() {
	# Resolves the branch/tag that an update should target, applying the
	# "latest reachable tag" release policy (see
	# git_resolve_update_target_into's doc comment). RequestedBranch defaults
	# to the current branch when empty; if that default is itself a tag
	# (i.e. currently on a release), resolves to the best branch first so
	# the policy has a real branch to compare against. Returns non-zero (with
	# empty output) only when no branch could be determined at all.
	local -n _drubi_out_="${1}"
	assert_nameref_is_string "${1}"
	local RequestedBranch=${2-}

	local CurrentBranch
	ds_branch_into CurrentBranch

	if [[ -z ${RequestedBranch-} ]]; then
		RequestedBranch="${CurrentBranch}"
		if ds_tag_exists "${RequestedBranch-}"; then
			ds_best_branch_into RequestedBranch
		fi
	fi
	if [[ -z ${RequestedBranch-} ]]; then
		_drubi_out_=""
		return 1
	fi

	git_resolve_update_target_into _drubi_out_ "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH}" "${RequestedBranch}" "${CurrentBranch}"
}

ds_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	if [[ -z ${CurrentRef-} && -z ${TargetRef-} ]]; then
		# Compares resolved version strings rather than raw commit hashes:
		# a detached HEAD (checked out at a release tag) has no upstream,
		# and origin/main is routinely ahead of the latest tag between
		# releases, so a hash-based compare would report an update as
		# available even when already on the latest release.
		local TargetBranch
		if ! ds_resolve_update_branch_into TargetBranch; then
			return 1
		fi
		local CurrentVersion RemoteVersion
		ds_version_into CurrentVersion
		ds_version_into RemoteVersion "${TargetBranch}"
		[[ ${CurrentVersion-} != "${RemoteVersion-}" ]]
		return $?
	fi
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

templates_resolve_update_branch_into() {
	# templates_ counterpart to ds_resolve_update_branch_into -- see its doc
	# comment. Shared by update_templates and templates_update_available.
	local -n _trubi_out_="${1}"
	assert_nameref_is_string "${1}"
	local RequestedBranch=${2-}

	local CurrentBranch
	templates_branch_into CurrentBranch

	if [[ -z ${RequestedBranch-} ]]; then
		RequestedBranch="${CurrentBranch}"
		if templates_tag_exists "${RequestedBranch-}"; then
			templates_best_branch_into RequestedBranch
		fi
	fi
	if [[ -z ${RequestedBranch-} ]]; then
		_trubi_out_=""
		return 1
	fi

	git_resolve_update_target_into _trubi_out_ "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH}" "${RequestedBranch}" "${CurrentBranch}"
}

templates_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	if [[ -z ${CurrentRef-} && -z ${TargetRef-} ]]; then
		# Compares resolved version strings rather than raw commit hashes:
		# a detached HEAD (checked out at a release tag, the normal state
		# for Templates) has no upstream, and origin/main is routinely
		# ahead of the latest tag between releases, so a hash-based compare
		# would report an update as available even when already on the
		# latest release.
		local TargetBranch
		if ! templates_resolve_update_branch_into TargetBranch; then
			return 1
		fi
		local CurrentVersion RemoteVersion
		templates_version_into CurrentVersion
		templates_version_into RemoteVersion "${TargetBranch}"
		[[ ${CurrentVersion-} != "${RemoteVersion-}" ]]
		return $?
	fi
	git_update_available "${TEMPLATES_PARENT_FOLDER}" "${CurrentRef-}" "${TargetRef-}"
}

git_checkout_latest_release_after_clone() {
	# Called only right after a fresh clone whose tip is on DefaultBranch and
	# therefore always at or ahead of the latest tag -- git_resolve_update_
	# target_into's "no update" ancestor check would always fire here, so
	# this resolves the latest reachable tag directly instead, bypassing
	# that check, and skips entirely (no checkout, no logging) when the
	# cloned tip already is that release.
	local GitPath=${1}
	local DefaultBranch=${2}
	local TargetName=${3}

	local LatestTag
	git_latest_reachable_tag_into LatestTag "${GitPath}" "${DefaultBranch}"
	if [[ -z ${LatestTag} ]]; then
		# No tagged release reachable yet -- the default branch's tip stands.
		return 0
	fi
	local TagHash HeadHash
	TagHash=$(git -C "${GitPath}" rev-parse --quiet --verify "${LatestTag}^{commit}" 2> /dev/null) || true
	HeadHash=$(git -C "${GitPath}" rev-parse --quiet --verify HEAD 2> /dev/null) || true
	if [[ -n ${TagHash} && ${TagHash} == "${HeadHash}" ]]; then
		# The cloned tip already is the latest release -- nothing to check out.
		return 0
	fi

	notice "Checking out {{|ApplicationName|}}${TargetName}{{[-]}} release '{{|Version|}}${LatestTag}{{[-]}}'"
	RunAndLog info "git:info" \
		fatal "Failed to switch to github ref '{{|Branch|}}${LatestTag}{{[-]}}'." \
		git -C "${GitPath}" checkout --force "${LatestTag}"
	info "Cleaning up unnecessary files and optimizing the local repository."
	RunAndLog info "git:info" \
		"" "" \
		git -C "${GitPath}" gc || true
	local UpdatedVersion
	git_version_into UpdatedVersion "${GitPath}"
	notice "Updated ${TargetName} to '{{|Version|}}${UpdatedVersion}{{[-]}}'"
}

templates_checkout_latest_release_after_clone() {
	git_checkout_latest_release_after_clone "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH}" "${TEMPLATES_NAME}"
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
		if git -C "${GitPath}" show-ref --quiet --verify "refs/remotes/origin/${DefaultBranch}" 2> /dev/null; then
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
