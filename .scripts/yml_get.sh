#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

yml_get() {
    local APPNAME=${1:-}
    local GET_VAR=${2:-}
    local FILENAME=${APPNAME,,}
    if /usr/local/bin/yq-go r "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" "${GET_VAR}" > /dev/null 2>&1; then
        /usr/local/bin/yq-go r "${SCRIPTPATH}/compose/.apps/${FILENAME}/${FILENAME}.yml" "${GET_VAR}" | grep -v '^null$'
    else
        return 1
    fi
}

test_yml_get() {
    run_script 'yml_get' PORTAINER "services.portainer.labels[com.dockstarter.appinfo.nicename]"
}
