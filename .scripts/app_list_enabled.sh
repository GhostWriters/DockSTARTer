#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_enabled() {
    local APPNAME_REGEX='[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local -a ENABLED_APPS

    readarray -t ENABLED_APPS < <(
        grep --color=never -o -P "^${APPNAME_REGEX}(?=__ENABLED\s*=(?<quote>['|\"]?)(?i:on|true|yes)\k<quote>)" "${COMPOSE_ENV}" | sort || true
    )
    for AppName in "${ENABLED_APPS[@]}"; do
        if [[ -d "$(run_script 'app_instance_folder' "${AppName}")" ]]; then
            echo "${AppName}"
        fi
    done
}

test_app_list_enabled() {
    # run_script 'app_list_enabled'
    warn "CI does not test app_list_enabled."
}
