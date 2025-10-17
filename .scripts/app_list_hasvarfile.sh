#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    find
)

app_list_hasvarfile() {
    ${FIND} "${COMPOSE_FOLDER}" -maxdepth 1 -type f -name '.env.app.*' ! -name '.env.app.' 2> /dev/null |
        tr -s '\n' |
        run_script 'varfile_to_appname_pipe' |
        sort
}

test_app_list_hasvarfile() {
    run_script 'app_list_hasvarfile'
}
