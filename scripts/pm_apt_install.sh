#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install() {
	local -a Dependencies=("$@")

	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	local Command
	if [[ -z "$(command -v apt-file)" ]]; then
		info "Installing '{{|Folder|}}apt-file{{[-]}}'."
		Command="sudo apt-get -y install apt-file"
		notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
		eval "${REDIRECT}${Command}" ||
			fatal \
				"Failed to install '{{|Folder|}}apt-file{{[-]}}' from apt." \
				"Failing command: {{|FailingCommand|}}${Command}"
	fi
	notice "Updating package information."
	Command='sudo apt-file update'
	notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to get updates from apt." \
			"Failing command: {{|FailingCommand|}}${Command}"

	notice "Determining packages to install."
	local -a Packages
	readarray -t Packages < <(detect_packages "${Dependencies[@]}")

	if [[ ${#Packages[@]} -eq 0 ]]; then
		notice "No packages found to install."
		return
	fi

	#shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
	local PackagesString="${Packages[@]}"
	local pkglist="${PackagesString// /{{[-]}}\', \'{{|Folder|}}}"
	pkglist="{{[-]}}'{{|Folder|}}${pkglist}{{[-]}}'"

	notice "Installing packages: ${pkglist}"

	Command="sudo apt-get -y install ${PackagesString}"
	notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to install dependencies from apt." \
			"Failing command: {{|FailingCommand|}}${Command}"
}

detect_packages() {
	local -a Dependencies=("$@")

	Old_IFS="${IFS}"
	IFS='|'
	RegEx_Dependencies="(${Dependencies[*]})"
	RegEx_Package_Blacklist="^(${PM_PACKAGE_BLACKLIST[*]-})$"
	IFS="${Old_IFS}"

	local RegEx_AptFile="^(.*):.*/s?bin/${RegEx_Dependencies}$"

	for Dep in "${Dependencies[@]}"; do
		if [[ -v PM_DEP_PACKAGE["${Dep}"] ]]; then
			echo "${PM_DEP_PACKAGE["${Dep}"]}"
			continue
		fi
		local Command="apt-file search bin/${Dep}"
		notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
		eval "${Command}" 2> /dev/null
	done | while IFS= read -r line; do
		if [[ ${line} =~ ${RegEx_AptFile} ]]; then
			local Package="${BASH_REMATCH[1]}"
			if [[ ! ${Package} =~ ${RegEx_Package_Blacklist} ]]; then
				echo "${Package}"
			fi
		fi
	done | sort -u
}

test_pm_apt_install() {
	run_script 'pm_apt_repos'
	run_script 'pm_apt_install'
}
