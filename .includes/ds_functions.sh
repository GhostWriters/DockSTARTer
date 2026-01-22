#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

git_branch() {
	local GitPath=${1}
	local DefaultBranch=${2-}
	local LegacyBranch=${3-}
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	git fetch --quiet --tags &> /dev/null || true
	git symbolic-ref --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null || git_best_branch "${GitPath}" "${DefaultBranch-}" "${LegacyBranch-}"
	popd &> /dev/null
}

git_branch_exists() {
	local GitPath=${1}
	local Branch=${2-}
	pushd "${GitPath}" &> /dev/null || return 1
	git ls-remote --quiet --exit-code --heads origin "${Branch}" &> /dev/null
	local result=$?
	popd &> /dev/null
	return ${result}
}

git_tag_exists() {
	local GitPath=${1}
	local Tag=${2-}
	pushd "${GitPath}" &> /dev/null || return 1
	git ls-remote --quiet --exit-code --tags origin "${Tag}" &> /dev/null
	local result=$?
	popd &> /dev/null
	return ${result}
}

git_commit_exists() {
	local GitPath=${1}
	local Commit=${2-}
	[[ ${Commit} =~ ^[0-9a-fA-F]{7,40}$ ]] || return 1
	pushd "${GitPath}" &> /dev/null || return 1
	git rev-parse --quiet --verify "${Commit}^{commit}" &> /dev/null
	local result=$?
	popd &> /dev/null
	return ${result}
}

git_version() {
	local GitPath=${1}
	local CheckBranch=${2-}
	local commitish Branch result
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""

	if [[ -n ${CheckBranch-} ]]; then
		if git show-ref --quiet --tags "${CheckBranch}" &> /dev/null; then
			commitish="${CheckBranch}"
			Branch="${CheckBranch}"
		elif git ls-remote --quiet --exit-code --heads origin "${CheckBranch}" &> /dev/null; then
			commitish="origin/${CheckBranch}"
			Branch="${CheckBranch}"
		elif git rev-parse --quiet --verify "${CheckBranch}^{commit}" &> /dev/null; then
			commitish="${CheckBranch}"
			# Try to find a branch name if we were given a SHA
			Branch="$(git_best_branch "${GitPath}")"
			if [[ -z ${Branch-} ]]; then
				Branch="${CheckBranch}"
			fi
		else
			commitish="origin/${CheckBranch}"
			Branch="${CheckBranch}"
		fi
	else
		commitish='HEAD'
		# We need to know which repo we're in to pass the right defaults to git_branch
		if [[ ${GitPath} == "${SCRIPTPATH}" ]]; then
			Branch="$(ds_branch)"
		elif [[ ${GitPath} == "${TEMPLATES_PARENT_FOLDER}" ]]; then
			Branch="$(templates_branch)"
		else
			Branch="$(git_branch "${GitPath}")"
		fi
	fi

	if [[ -z ${CheckBranch-} ]] || git_branch_exists "${GitPath}" "${Branch}" || git_tag_exists "${GitPath}" "${Branch}" || git_commit_exists "${GitPath}" "${Branch}"; then
		# Get the current tag. If no tag, use the commit instead.
		local VersionString
		VersionString="$(git describe --tags --exact-match "${commitish}" 2> /dev/null || true)"
		if [[ -n ${VersionString-} ]]; then
			if [[ ${VersionString} != "${Branch}" ]] && [[ ${Branch} != "main" || ${VersionString} == "main" ]]; then
				VersionString="${Branch} ${VersionString}"
			fi
		else
			local CommitHash
			CommitHash="$(git rev-parse --short "${commitish}" 2> /dev/null || true)"
			if [[ ${CommitHash} == "${Branch}" ]]; then
				VersionString="commit ${CommitHash}"
			else
				VersionString="${Branch} commit ${CommitHash}"
			fi
		fi
	else
		VersionString=''
	fi
	echo "${VersionString}"
	popd &> /dev/null
}

git_update_available() {
	local GitPath=${1}
	local CurrentRef=${2-}
	local TargetRef=${3-}
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	git fetch --quiet --tags &> /dev/null || true
	local -i result=0
	local Current Remote
	Current=$(git rev-parse HEAD 2> /dev/null || true)

	if [[ -n ${CurrentRef} ]]; then
		if [[ -z ${TargetRef-} ]]; then
			TargetRef="${CurrentRef}"
		fi

		# If CurrentRef is a tag, we compare against TargetRef (usually a branch)
		# Even if it's a tag, we compare the current hash against the target branch/ref hash
		Remote=$(git rev-parse "origin/${TargetRef}" 2> /dev/null || true)
		[[ ${Current} != "${Remote}" ]]
		result=$?
	else
		# Default behavior: compare HEAD to upstream
		Remote=$(git rev-parse '@{u}' 2> /dev/null || true)
		if [[ -n ${Remote} ]]; then
			[[ ${Current} != "${Remote}" ]]
			result=$?
		else
			# No upstream (detached), check against origin/main as fallback
			Remote=$(git rev-parse "origin/main" 2> /dev/null || true)
			[[ ${Current} != "${Remote}" ]]
			result=$?
		fi
	fi
	popd &> /dev/null
	return ${result}
}

ds_branch() {
	git_branch "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH-}" "${APPLICATION_LEGACY_BRANCH-}"
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
ds_version() {
	local Branch=${1-}
	git_version "${SCRIPTPATH}" "${Branch-}"
}
ds_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	git_update_available "${SCRIPTPATH}" "${CurrentRef-}" "${TargetRef-}"
}

templates_branch() {
	git_branch "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH-}"
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
templates_version() {
	local Branch=${1-}
	git_version "${TEMPLATES_PARENT_FOLDER}" "${Branch-}"
}
templates_update_available() {
	local CurrentRef=${1-}
	local TargetRef=${2-}
	git_update_available "${TEMPLATES_PARENT_FOLDER}" "${CurrentRef-}" "${TargetRef-}"
}

ds_switch_branch() {
	local CurrentBranch
	CurrentBranch="$(ds_branch)"
	if [[ ${CurrentBranch} == "${APPLICATION_LEGACY_BRANCH}" ]] && ds_branch_exists "${APPLICATION_DEFAULT_BRANCH}"; then
		export FORCE=true
		export PROMPT="CLI"
		notice \
			"Automatically switching from ${C["ApplicationName"]-}${APPLICATION_NAME}${NC-} branch '${C["Branch"]}${APPLICATION_LEGACY_BRANCH}${NC}' to '${C["Branch"]}${APPLICATION_DEFAULT_BRANCH}${NC}'."
		run_script 'update_self' "${APPLICATION_DEFAULT_BRANCH}" "${ARGS[@]}"
		exit
	fi
}

git_best_branch() {
	local GitPath=${1}
	local DefaultBranch=${2-}
	local LegacyBranch=${3-}
	pushd "${GitPath}" &> /dev/null || return 1
	local -a Branches=()
	# Get remote branches containing current HEAD
	readarray -t Branches < <(git branch -r --contains HEAD 2> /dev/null | sed 's/^[[:space:]]*origin\///' | grep -v 'HEAD ->')
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
		if git show-ref --quiet --verify "refs/remotes/origin/${DefaultBranch}"; then
			BestBranch="${DefaultBranch}"
		fi
	fi

	# 5. Fallback to Default Branch
	if [[ -z ${BestBranch} ]]; then
		BestBranch="${DefaultBranch}"
	fi
	echo "${BestBranch}"
	popd &> /dev/null
}

ds_best_branch() {
	git_best_branch "${SCRIPTPATH}" "${APPLICATION_DEFAULT_BRANCH-}" "${APPLICATION_LEGACY_BRANCH-}"
}

templates_best_branch() {
	git_best_branch "${TEMPLATES_PARENT_FOLDER}" "${TEMPLATES_DEFAULT_BRANCH-}"
}
