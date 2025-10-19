#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_yum_install() {
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

    Command="sudo yum -y install ${PackagesString}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${REDIRECT}${Command}" ||
        fatal \
            "Failed to install dependencies from yum.\n" \
            "Failing command: ${C["FailingCommand"]}${Command}"
}

detect_packages() {
    local -a Dependencies=("$@")

    if [[ -z "$(command -v repoquery)" ]]; then
        info "Installing '${C["Program"]}repoquery${NC}'."
        Command="sudo yum -y install yum-utils"
        notice "Running: ${C["RunningCommand"]}${Command}${NC}"
        eval "${REDIRECT}${Command}" ||
            fatal \
                "Failed to install '${C["Program"]}repoquery${NC}' from yum.\n" \
                "Failing command: ${C["FailingCommand"]}${Command}"
    fi

    Old_IFS="${IFS}"
    IFS='|'
    RegEx_Package_Blacklist="(${PM_PACKAGE_BLACKLIST[*]-})"
    IFS="${Old_IFS}"

    local DepsSearch
    DepsSearch="$(printf '*/bin/%s ' "${Dependencies[@]}" | xargs)"
    local Command="repoquery --whatprovides ${DepsSearch} --qf %{name}"
    notice "Running: ${C["RunningCommand"]}${Command}${NC}"
    eval "${Command}" 2> /dev/null | while IFS= read -r line; do
        if [[ ! ${line} =~ ^${RegEx_Package_Blacklist}$ ]]; then
            echo "${line}"
        fi
    done | sort -u
}

test_pm_yum_install() {
    # run_script 'pm_yum_repos'
    # run_script 'pm_yum_install'
    warn "CI does not test pm_yum_install."
}
