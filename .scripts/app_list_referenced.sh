#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_referenced() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    #local APPFILE_REGEX='^[a-z][a-z0-9]*(__[a-z0-9]+)?$'

    local -al ReferencedApps=()

    # Add the list of apps with .env.app.appname files with variables in them
    local -au AppList
    readarray -t AppList < <(
        run_script 'app_list_hasvarfile'
    )
    for AppName in "${AppList[@]-}"; do
        if [[ -n ${AppName} && -n $(run_script 'appvars_list' "${AppName}:") ]]; then
            ReferencedApps+=("${AppName}")
        fi
    done

    # Add the list of referenced apps in the global .env file
    local REFERENCED_APPS_REGEX="^${APPNAME_REGEX}(?=__[A-Za-z0-9]\w*\s*=)"
    readarray -O ${#ReferencedApps[@]} ReferencedApps < <(
        grep --color=never -o -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_ENV}" 2> /dev/null || true
    )

    # Add the list of referenced apps in the override file
    REFERENCED_APPS_REGEX="^(?:[^#]*)(?:^|\s)(?<Q>['\"]?)[.]env[.]app[.]\K([a-z][a-z0-9]*(?:__[a-z0-9]+)?)(?=\k<Q>\s|$)"
    readarray -O ${#ReferencedApps[@]} ReferencedApps < <(
        grep --color=never -o -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_OVERRIDE}" 2> /dev/null || true
    )

    # Output the sorted list, removing duplicates
    if [[ -n ${ReferencedApps[*]-} ]]; then
        sort -u < <(printf '%s\n' "${ReferencedApps[@]}" | tr -s '\n')
    fi
}

test_app_list_referenced() {
    run_script 'app_list_referenced'
    #warn "CI does not test app_list_referenced."
}
