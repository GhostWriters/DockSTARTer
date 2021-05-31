#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_repos() {
    local MINIMUM_LIBSECCOMP2="2.4"
    local INSTALLED_LIBSECCOMP2
    INSTALLED_LIBSECCOMP2=$(apt-cache policy libseccomp2 | grep -Po 'Installed: \K.*')
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2}"; then
        info "Installing buster-backports repo for libseccomp2."
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC 648ACFD622F3D138 || error "Failed to get apt key for buster-backports repo."
        echo "deb http://deb.debian.org/debian buster-backports main" | tee -a /etc/apt/sources.list.d/buster-backports.list || error "Failed to add buster-backports repo to sources."
    fi
    info "Updating repositories."
    apt-get -y update > /dev/null 2>&1 || fatal "Failed to get updates from apt.\nFailing command: ${F[C]}apt-get -y update"
    if vergt "${MINIMUM_LIBSECCOMP2}" "${INSTALLED_LIBSECCOMP2}"; then
        info "Installing libseccomp2 from buster-backports repo."
        apt install -t buster-backports libseccomp2 || error "Failed to install libseccomp2 from buster-backports repo."
    fi
}

test_pm_apt_repos() {
    run_script 'pm_apt_repos'
}
