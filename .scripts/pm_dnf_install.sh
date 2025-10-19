#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_dnf_install() {
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

    Command="sudo dnf -y install ${PackagesString}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal \
            "Failed to install dependencies from dnf.\n" \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

detect_packages() {
    local -a Dependencies=("$@")

    Old_IFS="${IFS}"
    IFS=','
    Package_Blacklist="${PM_PACKAGE_BLACKLIST[*]-}"
    IFS="${Old_IFS}"

    local DepsSearch
    DepsSearch="$(printf '*/bin/%s ' "${Dependencies[@]}" | xargs)"
    local Command="dnf --exclude \"${Package_Blacklist}\" rq ${DepsSearch} --qf %{name}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${Command}" 2> /dev/null ||
        fatal \
            "Failed to find packages to install.\n" \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

test_pm_dnf_install() {
    # run_script 'pm_dnf_repos'
    # run_script 'pm_dnf_install'
    warn "CI does not test pm_dnf_install."
}
