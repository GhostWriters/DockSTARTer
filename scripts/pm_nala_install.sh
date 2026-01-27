#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_nala_install() {
	local -a Dependencies=("$@")

	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	local Command
	if [[ -z "$(command -v apt-file)" ]]; then
		info "Installing '${C["Program"]}apt-file${NC}'."
		Command="sudo nala install --no-update -y apt-file"
		notice "Running: ${C["RunningCommand"]}${Command}${NC}"
		eval "${REDIRECT}${Command}" ||
			fatal \
				"Failed to install '${C["Program"]}apt-file${NC}' from nala." \
				"Failing command: ${C["FailingCommand"]}${Command}"
	fi
	notice "Updating package information."
	Command='sudo apt-file update'
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to get updates from apt-file." \
			"Failing command: ${C["FailingCommand"]}${Command}"

	notice "Determining packages to install."
	local -a Packages
	readarray -t Packages < <(detect_packages "${Dependencies[@]}")

	if [[ ${#Packages[@]} -eq 0 ]]; then
		notice "No packages found to install."
		return
	fi

	#shellcheck disable=SC2124 #Assigning an array to a string! Assign as array, or use * instead of @ to concatenate.
	local PackagesString="${Packages[@]}"
	local pkglist="${PackagesString// /${NC}\', \'${C["Program"]}}"
	pkglist="${NC}'${C["Program"]}${pkglist}${NC}'"

	notice "Installing packages: ${pkglist}"

	Command="sudo nala install --no-update -y ${PackagesString}"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to install dependencies from nala." \
			"Failing command: ${C["FailingCommand"]}${Command}"
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
		notice "Running: ${C["RunningCommand"]}${Command}${NC}"
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

test_pm_nala_install() {
	#run_script 'pm_nala_repos'
	#run_script 'pm_nala_install'
	warn "CI does not test pm_nala_install."
}
