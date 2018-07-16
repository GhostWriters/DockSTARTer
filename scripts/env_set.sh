#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

env_set() {
    local SET_VAR
    SET_VAR=${1:-}
    local NEW_VAL
    NEW_VAL=${2:-}
    local VAR_VAL
    VAR_VAL=$(grep "${SET_VAR}" "${SCRIPTPATH}/compose/.env" | xargs || fatal "Could not find ${SET_VAR} in ${SCRIPTPATH}/compose/.env")
    local SED_FIND
    SED_FIND=$(echo "${VAR_VAL}" | sed -e 's/[\/&]/\\&/g')
    local SED_REPLACE
    SED_REPLACE=$(echo "${SET_VAR}=${NEW_VAL}" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/${SED_FIND}/${SED_REPLACE}/" "${SCRIPTPATH}/compose/.env"
}
