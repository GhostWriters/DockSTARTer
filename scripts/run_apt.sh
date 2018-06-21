#!/bin/bash

run_apt() {
    apt-get update
    if [[ ${CI} != true ]] && [[ ${TRAVIS} != true ]]; then
        apt-get -y dist-upgrade
    fi
    apt-get -qq install curl git grep
    apt-get -y autoremove
    apt-get -y autoclean
}
