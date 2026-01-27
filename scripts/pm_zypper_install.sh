#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_zypper_install() {
	local -a Dependencies=("$@")

	local REDIRECT='&> /dev/null '
	if [[ -n ${VERBOSE-} ]]; then
		REDIRECT='2>&1 '
	fi

	local Command

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

	Command="sudo zypper -n install ${PackagesString}"
	notice "Running: ${C["RunningCommand"]}${Command}${NC}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to install dependencies from zypper." \
			"Failing command: ${C["FailingCommand"]}${Command}"
}

detect_packages() {
	local -a Dependencies=("$@")

	local RegEx_Package_Blacklist DepsSearch
	local Old_IFS="${IFS}"
	IFS='|'
	local DepsSearch="/s?bin/(${Dependencies[*]})/"
	local RegEx_Package_Blacklist="^(${PM_PACKAGE_BLACKLIST[*]-})$"
	IFS="${Old_IFS}"

	local RegEx_XML='name="([A-Za-z0-9_-]*)"'
	local -a Command=(zypper -x search -f --provides "\"${DepsSearch}\"")
	Old_IFS="${IFS}"
	IFS=' '
	local CommandString="${Command[*]}"
	IFS="${Old_IFS}"
	notice "Running: ${C["RunningCommand"]}${CommandString}${NC}"
	"${Command[@]}" 2> /dev/null | while IFS= read -r line; do
		if [[ ${line} =~ ${RegEx_XML} ]]; then
			local Package="${BASH_REMATCH[1]}"
			notice "${Package} =~ ${RegEx_Package_Blacklist}"
			if [[ ! ${Package} =~ ${RegEx_Package_Blacklist} ]]; then
				echo "${Package}"
			fi
		fi
	done | sort -u
}

test_pm_zypper_install() {
	# run_script 'pm_zypper_repos'
	# run_script 'pm_zypper_install'
	warn "CI does not test pm_zypper_install."
}
