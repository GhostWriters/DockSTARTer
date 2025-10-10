#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare Prefix="yml_merge_"

needs_yml_merge() {
    if [[ -n ${FORCE-} ]]; then
        return 0
    fi

    if [[ ! -f ${DOCKER_COMPOSE_FILE} ]]; then
        # Compose file doesn't exists, return true
        return 0
    fi

    if file_changed "${DOCKER_COMPOSE_FILE}"; then
        # Compose file has changed, return true
        return 0
    fi
    if file_changed "${COMPOSE_ENV}"; then
        # .env has changed, return true
        return 0
    fi
    for AppName in $(run_script 'app_list_enabled'); do
        if file_changed "$(run_script 'app_env_file' "${AppName}")"; then
            # .env.app.appname has changed, return true
            return 0
        fi
    done

    # No files have changed, return false
    return 1
}

file_changed() {
    local file=${1-}
    local timestamp_file
    timestamp_file="${TIMESTAMPS_FOLDER:?}/${Prefix}$(basename "${file}")"
    if [[ ! -f ${file} && ! -f ${timestamp_file} ]]; then
        return 1
    elif [[ -f ${file} && ! -f ${timestamp_file} ]]; then
        return 0
    elif [[ ! -f ${file} && -f ${timestamp_file} ]]; then
        return 0
    fi
    [[ $(stat -c %Y "${file}") != $(stat -c %Y "${timestamp_file}") ]]
}

test_needs_yml_merge() {
    warn "CI does not test needs_yml_merge."
}
