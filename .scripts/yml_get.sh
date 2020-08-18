#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

yml_get() {
    local APPNAME=${1:-}
    local GET_VAR=${2:-}
    local FILENAME=${APPNAME,,}
    run_script 'install_yq'
    /usr/local/bin/yq-go m "${SCRIPTPATH}"/compose/.apps/"${FILENAME}"/*.yml 2> /dev/null | /usr/local/bin/yq-go r - "${GET_VAR}" 2> /dev/null || return 1
}

test_yml_get() {
    run_script 'yml_get' WATCHTOWER "services.watchtower.labels[com.dockstarter.appinfo.nicename]"
}
