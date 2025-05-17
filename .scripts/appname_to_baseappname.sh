#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_to_baseappname() {
    local AppName=${1-}
    echo "${AppName%__*}"
}

test_appname_to_baseappname() {
    for AppName in RADARR RADARR__4K; do
        notice "[${AppName}] [$(run_script 'appname_to_baseappname' "${AppName}")]"
    done
}
