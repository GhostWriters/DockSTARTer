#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_filter_runnable_pipe() {
    local -a Args
    readarray -t Args < /dev/stdin
    if [[ -n ${Args[*]-} ]]; then
        run_script 'app_filter_runnable' "${Args[@]}"
    fi
}

test_app_filter_runnable_pipe() {
    local AppList
    AppList="$(
        cat << EOF
WATCHTOWER
SAMBA RADARR
NZBGET NONEXISTENTAPP
EOF
    )"
    echo "Input List:"
    echo "${AppList}"
    echo "Output List:"
    echo "${AppList}" | run_script 'app_nicename_pipe'
}
