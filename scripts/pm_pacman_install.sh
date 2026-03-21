#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_pacman_install() {
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
	local pkglist="${PackagesString// /{{[-]}}\', \'{{|Folder|}}}"
	pkglist="{{[-]}}'{{|Folder|}}${pkglist}{{[-]}}'"

	notice "Installing packages: ${pkglist}"

	Command="sudo pacman -Sy --noconfirm ${PackagesString}"
	notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to install dependencies from pacman." \
			"Failing command: {{|FailingCommand|}}${Command}"
}

detect_packages() {
	local -a Dependencies=("$@")

	local Command
	if [[ -z "$(command -v pkgfile)" ]]; then
		info "Installing '{{|Folder|}}pkgfile{{[-]}}'."
		Command="sudo pacman -Sy --noconfirm pkgfile"
		notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
		eval "${REDIRECT}${Command}" ||
			fatal \
				"Failed to install '{{|Folder|}}pkgfile{{[-]}}' from pacman." \
				"Failing command: {{|FailingCommand|}}${Command}"
	fi
	notice "Updating package information."
	Command='sudo pkgfile -u'
	notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
	eval "${REDIRECT}${Command}" ||
		fatal \
			"Failed to get updates from pkgfile." \
			"Failing command: {{|FailingCommand|}}${Command}"

	local RegEx_Package_Blacklist
	if [[ ${#PM_PACKAGE_BLACKLIST[@]} -gt 0 ]]; then
		Old_IFS="${IFS}"
		IFS='|'
		RegEx_Package_Blacklist="^(${PM_PACKAGE_BLACKLIST[*]-})$"
		IFS="${Old_IFS}"
	fi

	for Dep in "${Dependencies[@]}"; do
		local Package
		Command="pkgfile -b ${Dep}"
		notice "Running: {{|RunningCommand|}}${Command}{{[-]}}"
		Package="$(eval "${Command}" 2> /dev/null)" ||
			fatal \
				"Failed to find packages to install." \
				"Failing command: {{|FailingCommand|}}${Command}"
		Package="${Package##*/}"
		if [[ -n ${Package} && (-z ${RegEx_Package_Blacklist-} || ! ${Package} =~ ${RegEx_Package_Blacklist}) ]]; then
			echo "${Package}"
		fi
	done | sort -u
}

test_pm_pacman_install() {
	# run_script 'pm_pacman_repos'
	# run_script 'pm_pacman_install'
	warn "CI does not test pm_pacman_install."
}
