#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    grep
)

pm_apt_repos() {
    local REDIRECT='&> /dev/null '
    if [[ -n ${VERBOSE-} ]]; then
        REDIRECT='2>&1 '
    fi

    notice "Updating repositories. Please be patient, this can take a while."
    local COMMAND=""
    local MINIMUM_APT_TRANSPORT_HTTPS="1"
    local INSTALLED_APT_TRANSPORT_HTTPS
    INSTALLED_APT_TRANSPORT_HTTPS=$(
        (sudo apt-cache policy apt-transport-https | ${GREP} --color=never -Po 'Installed: \K.*') || echo "0"
    )
    if vergt "${MINIMUM_APT_TRANSPORT_HTTPS}" "${INSTALLED_APT_TRANSPORT_HTTPS:-0}"; then
        COMMAND="sudo apt-get -y update"
        info "Updating repositories (before installing apt-transport-https)."
        notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
        eval "${REDIRECT}${COMMAND}" ||
            fatal \
                "Failed to get updates from apt.\n" \
                "Failing command: ${C["FailingCommand"]}${COMMAND}"

        COMMAND="sudo apt-get -y install apt-transport-https"
        info "Installing APT transport for downloading via the HTTP Secure protocol (HTTPS)."
        notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
        eval "${REDIRECT}${COMMAND}" ||
            fatal \
                "Failed to install apt-transport-https from apt.\n" \
                "Failing command: ${C["FailingCommand"]}${COMMAND}"
    fi
    local MINIMUM_LIBSECCOMP2="2.4.4"
    # Note compatibility from https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0
    local INSTALLED_LIBSECCOMP2
    INSTALLED_LIBSECCOMP2=$( (apt-cache policy libseccomp2 | ${GREP} --color=never -Po 'Installed: \K.*') || echo "0")
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2:-0}"; then
        info "Installing buster-backports repo for libseccomp2."
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 ||
            error \
                "Failed to get apt key for buster-backports repo.\n" \
                "Failing command: ${C["FailingCommand"]}sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138"
        echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list ||
            error \
                "Failed to add buster-backports repo to sources.\n" \
                "Failing command: ${C["FailingCommand"]}echo \"deb http://deb.debian.org/debian buster-backports main\" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list"
    fi
    COMMAND="sudo apt-get -y update"
    info "Updating repositories."
    notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
    eval "${REDIRECT}${COMMAND}" ||
        fatal \
            "Failed to get updates from apt.\n" \
            "Failing command: ${C["FailingCommand"]}${COMMAND}"
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2:-0}"; then
        COMMAND="sudo apt-get -y install -t buster-backports libseccomp2"
        info "Installing libseccomp2 from buster-backports repo."
        notice "Running: ${C["RunningCommand"]}${COMMAND}${NC}"
        eval "${REDIRECT}${COMMAND}" ||
            fatal \
                "Failed to install libseccomp2 from buster-backports repo.\n" \
                "Failing command: ${C["FailingCommand"]}${COMMAND}"
    fi
}

test_pm_apt_repos() {
    run_script 'pm_apt_repos'
}
