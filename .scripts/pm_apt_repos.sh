#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_repos() {
    notice "Updating repositories. Please be patient, this can take a while."
    local REDIRECT="> /dev/null 2>&1"
    if [[ -n ${VERBOSE-} ]] || run_script 'question_prompt' "${PROMPT:-CLI}" N "Would you like to display the command output?"; then
        REDIRECT=""
    fi
    local MINIMUM_APT_TRANSPORT_HTTPS="1"
    local INSTALLED_APT_TRANSPORT_HTTPS
    INSTALLED_APT_TRANSPORT_HTTPS=$( (sudo apt-cache policy apt-transport-https | grep --color=never -Po 'Installed: \K.*') || echo "0")
    if vergt "${MINIMUM_APT_TRANSPORT_HTTPS}" "${INSTALLED_APT_TRANSPORT_HTTPS:-0}"; then
        info "Updating repositories (before installing apt-transport-https)."
        eval "sudo apt-get -y update ${REDIRECT}" || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}sudo apt-get -y update"
        info "Installing APT transport for downloading via the HTTP Secure protocol (HTTPS)."
        eval "sudo apt-get -y install apt-transport-https ${REDIRECT}" || fatal "Failed to install apt-transport-https from apt.\nFailing command: ${F[C]}sudo apt-get -y install apt-transport-https"
    fi
    local MINIMUM_LIBSECCOMP2="2.4.4"
    # Note compatibility from https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0
    local INSTALLED_LIBSECCOMP2
    INSTALLED_LIBSECCOMP2=$( (apt-cache policy libseccomp2 | grep --color=never -Po 'Installed: \K.*') || echo "0")
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2:-0}"; then
        info "Installing buster-backports repo for libseccomp2."
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 || error "Failed to get apt key for buster-backports repo.\nFailing command: ${F[C]}sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138"
        echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list || error "Failed to add buster-backports repo to sources.\nFailing command: ${F[C]}echo \"deb http://deb.debian.org/debian buster-backports main\" | sudo tee -a /etc/apt/sources.list.d/buster-backports.list"
    fi
    info "Updating repositories."
    eval "sudo apt-get -y update ${REDIRECT}" || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}sudo apt-get -y update"
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2:-0}"; then
        info "Installing libseccomp2 from buster-backports repo."
        eval "sudo apt-get -y install -t buster-backports libseccomp2 ${REDIRECT}" || fatal "Failed to install libseccomp2 from buster-backports repo.\nFailing command: ${F[C]}sudo apt-get -y install -t buster-backports libseccomp2"
    fi
}

test_pm_apt_repos() {
    run_script 'pm_apt_repos'
}
