#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_set() {
    local SET_VAR=${1-}
    local NEW_VAL
    # https://unix.stackexchange.com/questions/422165/escape-double-quotes-in-variable/422170#422170
    NEW_VAL=$(printf "%s\n" "${2-}" | sed -e "s/'/'\"'\"'/g" -e "1s/^/'/" -e "\$s/\$/'/")
    local VAR_FILE=${3:-$COMPOSE_ENV}
    local VAR_VAL
    VAR_VAL=$(grep --color=never -P "^${SET_VAR}=" "${VAR_FILE}") || fatal "Failed to find ${SET_VAR} in ${VAR_FILE}\nFailing command: ${F[C]}grep --color=never -P \"^${SET_VAR}=\" \"${VAR_FILE}\""
    # https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed/29613573#29613573
    local SED_FIND
    SED_FIND=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "${VAR_VAL}")
    local SED_REPLACE
    SED_REPLACE=$(sed 's/[&/\]/\\&/g' <<< "${SET_VAR}=${NEW_VAL}")
    sed -i "s/^${SED_FIND}$/${SED_REPLACE}/" "${VAR_FILE}" || fatal "Failed to set ${SED_REPLACE}\nFailing command: ${F[C]}sed -i \"s/^${SED_FIND}$/${SED_REPLACE}/\" \"${VAR_FILE}\""
}

test_env_set() {
    run_script 'appvars_create' WATCHTOWER
    run_script 'env_set' WATCHTOWER_ENABLED false
    run_script 'env_get' WATCHTOWER_ENABLED
    run_script 'appvars_purge' WATCHTOWER
}
