#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appname_is_valid() {
    local AppName=${1-}
    [[ "${AppName-}" =~ ^[a-zA-Z][a-zA-Z0-9]*(__[a-zA-Z0-9]+)?$ ]]
}

test_appname_is_valid() {
    for AppName in SONARR Sonarr SONARR_4K SONARR__4K "SONARR 4K" "SONARR:"; do
        if run_script 'appname_is_valid' "${AppName}"; then
            notice "[${AppName}] is valid"
        else
            notice "[${AppName}] is not valid"
        fi
    done
}
