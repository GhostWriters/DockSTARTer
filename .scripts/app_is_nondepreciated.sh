#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_nondepreciated() {
    local APPNAME=${1-}
    local FILENAME=${APPNAME,,}
    local LABELS_FILE
    LABELS_FILE="$(run_script 'instance_file' "${APPNAME}" ".labels.yml")"
    local APP_DEPRECIATED
    if [[ -f ${LABELS_FILE} ]]; then
        APP_DEPRECIATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)
    fi
    if [[ ${APP_DEPRECIATED-} == "false" ]]; then
        return 0
    else
        return 1
    fi
}

test_app_is_nondepreciated() {
    run_script 'app_is_nondepreciated' WATCHTOWER
    notice "'app_is_nondepreciated' WATCHTOWER returned $?"
    run_script 'app_is_nondepreciated' SAMBA
    notice "'app_is_nondepreciated' SAMBA returned $?"
    run_script 'app_is_nondepreciated' APPTHATDOESNOTEXIST
    notice "'app_is_nondepreciated' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_nondepreciated."
}
