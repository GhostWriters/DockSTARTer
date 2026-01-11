#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

git_branch() {
	local GitPath=${1}
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	git fetch --quiet &> /dev/null || true
	git symbolic-ref --short HEAD 2> /dev/null || true
	popd &> /dev/null
}

git_branch_exists() {
	local GitPath=${1}
	local CurrentBranch
	CurrentBranch="$(git_branch "${GitPath}")"
	local CheckBranch=${2:-"${CurrentBranch}"}
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	local -i result=0
	git ls-remote --exit-code --heads origin "${CheckBranch}" &> /dev/null || result=$?
	popd &> /dev/null
	return ${result}
}

git_version() {
	local GitPath=${1}
	local CheckBranch=${2-}
	local commitish Branch
	if [[ -n ${CheckBranch-} ]]; then
		commitish="origin/${CheckBranch}"
		Branch="${CheckBranch}"
	else
		commitish='HEAD'
		Branch="$(git_branch "${GitPath}")"
	fi

	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	if [[ -z ${CheckBranch-} ]] || ds_branch_exists "${Branch}"; then
		# Get the current tag. If no tag, use the commit instead.
		local VersionString
		VersionString="$(git describe --tags --exact-match "${commitish}" 2> /dev/null || true)"
		if [[ -z ${VersionString-} ]]; then
			VersionString="commit $(git rev-parse --short "${commitish}" 2> /dev/null || true)"
		fi
		VersionString="${Branch} ${VersionString}"
	else
		VersionString=''
	fi
	echo "${VersionString}"
	popd &> /dev/null
}

git_update_available() {
	local GitPath=${1}
	pushd "${GitPath}" &> /dev/null ||
		fatal \
			"Failed to change directory." \
			"Failing command: ${C["FailingCommand"]}pushd \"${GitPath}\""
	git fetch --quiet &> /dev/null
	local -i result=0
	# shellcheck disable=SC2319 # This $? refers to a condition, not a command. Assign to a variable to avoid it being overwritten.
	[[ $(git rev-parse HEAD 2> /dev/null) != $(git rev-parse '@{u}' 2> /dev/null) ]] || result=$?
	popd &> /dev/null
	return ${result}
}

ds_branch() {
	git_branch "${SCRIPTPATH}"
}
ds_branch_exists() {
	local Branch=${1-}
	git_branch_exists "${SCRIPTPATH}" "${Branch-}"
}
ds_version() {
	local Branch=${1-}
	git_version "${SCRIPTPATH}" "${Branch-}"
}
ds_update_available() {
	git_update_available "${SCRIPTPATH}"
}

templates_branch() {
	git_branch "${TEMPLATES_PARENT_FOLDER}"
}
templates_branch_exists() {
	local Branch=${1-}
	git_branch_exists "${TEMPLATES_PARENT_FOLDER}" "${Branch-}"
}
templates_version() {
	local Branch=${1-}
	git_version "${TEMPLATES_PARENT_FOLDER}" "${Branch-}"
}
templates_update_available() {
	git_update_available "${TEMPLATES_PARENT_FOLDER}"
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
