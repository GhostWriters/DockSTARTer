#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

env_set() {
    local SET_VAR
    SET_VAR=${1:-}
    local NEW_VAL
    NEW_VAL=${2:-}
    local VAR_VAL
    VAR_VAL=$(grep "^${SET_VAR}=" "${SCRIPTPATH}/compose/.env" | xargs) || fatal "Failed to find ${SET_VAR} in ${SCRIPTPATH}/compose/.env"
    sed -i "s/^$(sed_find "${VAR_VAL}")$/$(sed_replace "${SET_VAR}=${NEW_VAL}")/" "${SCRIPTPATH}/compose/.env" || fatal "Failed to set ${SED_REPLACE}"
}
