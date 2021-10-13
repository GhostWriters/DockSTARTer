#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_repos() {
    local MINIMUM_APT_TRANSPORT_HTTPS="1"
    local INSTALLED_APT_TRANSPORT_HTTPS
    INSTALLED_APT_TRANSPORT_HTTPS=$(apt-cache policy apt-transport-https | grep -Po 'Installed: \K.*')
    if vergt "${MINIMUM_APT_TRANSPORT_HTTPS}" "${INSTALLED_APT_TRANSPORT_HTTPS}"; then
        info "Updating repositories (before installing apt-transport-https)."
        apt-get -y update > /dev/null 2>&1 || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}apt-get -y update"
        info "Installing APT transport for downloading via the HTTP Secure protocol (HTTPS)."
        apt-get -y install apt-transport-https > /dev/null 2>&1 || fatal "Failed to install apt-transport-https from apt.\nFailing command: ${F[C]}apt-get -y install apt-transport-https"
    fi
    local MINIMUM_LIBSECCOMP2="2.4.4"
    # Note compatibility from https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0
    local INSTALLED_LIBSECCOMP2
    INSTALLED_LIBSECCOMP2=$(apt-cache policy libseccomp2 | grep -Po 'Installed: \K.*')
    if vergte "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2}"; then
        info "Installing buster-backports repo for libseccomp2."
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 || error "Failed to get apt key for buster-backports repo."
        echo "deb http://deb.debian.org/debian buster-backports main" | tee -a /etc/apt/sources.list.d/buster-backports.list || error "Failed to add buster-backports repo to sources."
    fi
    info "Updating repositories."
    apt-get -y update > /dev/null 2>&1 || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}apt-get -y update"
    if vergte "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2}"; then
        info "Installing libseccomp2 from buster-backports repo."
        apt-get -y install -t buster-backports libseccomp2 || fatal "Failed to install libseccomp2 from buster-backports repo."
    fi
}

test_pm_apt_repos() {
    run_script 'pm_apt_repos'
}
