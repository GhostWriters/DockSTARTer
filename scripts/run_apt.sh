#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run_apt() {
    apt-get update
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        apt-get -y dist-upgrade
    fi
    apt-get -qq install curl git grep sed apt-transport-https whiptail
    apt-get -y autoremove
    apt-get -y autoclean
}
