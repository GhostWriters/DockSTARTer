#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_list_referenced() {
    local APPNAME_REGEX='^[A-Z][A-Z0-9]*(__[A-Z0-9]+)?'
    local APPFILE_REGEX='^[a-z][a-z0-9]*(__[a-z0-9]+)?$'

    local -a ReferencedApps=()

    # Add the list of apps with appname.env an file with variables in it
    local -a AppEnvFileList
    readarray -t AppEnvFileList < <(find "${COMPOSE_FOLDER}"/.env.app.* 2> /dev/null || true)
    for AppEnvFile in "${AppEnvFileList[@]}"; do
        local AppName="${AppEnvFile##*.}"
        if [[ ${AppName} =~ ${APPFILE_REGEX} && -n $(run_script 'appvars_list' "${AppName}:") ]]; then
            ReferencedApps+=("${AppName^^}")
        fi
    done

    # Add the list of referenced apps in the global .env file
    local REFERENCED_APPS_REGEX="${APPNAME_REGEX}(?=__[A-Za-z0-9]\w*\s*=)"
    readarray -O ${#ReferencedApps[@]} ReferencedApps <<< "$(
        grep --color=never -o -P "${REFERENCED_APPS_REGEX}" "${COMPOSE_ENV}" 2> /dev/null || true
    )"

    # Output the sorted list, removing duplicates
    sort -u <<< "$(printf '%s\n' "${ReferencedApps[@]}")"
}

test_app_list_referenced() {
    run_script 'app_list_referenced'
    #warn "CI does not test app_list_referenced."
}
