#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_set() {
    local SET_VAR
    SET_VAR=${1:-}
    local NEW_VAL
    NEW_VAL=${2:-}
    local VAR_VAL
    VAR_VAL=$(grep --color=never "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env") || fatal "Failed to find ${SET_VAR} in ${SCRIPTPATH}/compose/.env"
    # https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed/29613573#29613573
    local SED_FIND
    SED_FIND=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "${VAR_VAL}")
    local SED_REPLACE
    SED_REPLACE=$(sed 's/[&/\]/\\&/g' <<< "${SET_VAR}=${NEW_VAL}")
    sed -i "s/^${SED_FIND}$/${SED_REPLACE}/" "${SCRIPTPATH}/compose/.env" || fatal "Failed to set ${SED_REPLACE}"
}

test_env_set() {
    run_script 'env_set' PORTAINER_ENABLED false
    run_script 'env_get' PORTAINER_ENABLED
}
