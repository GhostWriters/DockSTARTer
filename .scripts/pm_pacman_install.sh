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
    local pkglist="${PackagesString// /${NC}\', \'${C["Program"]}}"
    pkglist="${NC}'${C["Program"]}${pkglist}${NC}'"

    notice "Installing packages: ${pkglist}"

    Command="sudo pacman -Sy --noconfirm ${PackagesString}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal \
            "Failed to install dependencies from pacman." \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

detect_packages() {
    local -a Dependencies=("$@")

    local Command
    if [[ -z "$(command -v pkgfile)" ]]; then
        info "Installing '${C["Program"]}pkgfile${NC}'."
        Command="sudo pacman -Sy --noconfirm pkgfile"
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        eval "${REDIRECT}${Command}" ||
            fatal \
                "Failed to install '${C["Program"]}pkgfile${NC}' from pacman." \
                "Failing command: ${C["FailingCommand"]}${Command}"
    fi
    notice "Updating package information."
    Command='sudo pkgfile -u'
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal \
            "Failed to get updates from pkgfile." \
            "Failing command: ${C["FailingCommand"]}${Command}"

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
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        Package="$(eval "${Command}" 2> /dev/null)" ||
            fatal \
                "Failed to find packages to install." \
                "Failing command: ${C["FailingCommand"]}${Command}"
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
