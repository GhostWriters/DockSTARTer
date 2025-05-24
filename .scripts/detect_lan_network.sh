#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

detect_lan_network() {
    # https://github.com/tom472/mediabox/commit/d6a3317c9513ac9907715c76fb4459cba426da18
    # https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x#comment89955893_25851186
    local DETECTED_LAN_NETWORK
    DETECTED_LAN_NETWORK=$(ip a | grep -Po "$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')\/\d+" | sed 's/[0-9]*\//0\//')
    echo "${DETECTED_LAN_NETWORK}"
}

test_detect_lan_network() {
    run_script 'detect_lan_network'
}
