#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_depreciated() {
    local APPNAME=${1-}
    local FILENAME=${APPNAME,,}
    local LABELS_FILE="${TEMPLATES_FOLDER}/${FILENAME}/${FILENAME}.labels.yml"
    local APP_DEPRECATED
    if [[ -f ${LABELS_FILE} ]]; then
        APP_DEPRECIATED=$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)
    fi
    if [[ ${APP_DEPRECIATED-} == "true" ]]; then
        return 0
    else
        return 1
    fi
}

test_app_is_depreciated() {
    run_script 'app_is_depreciated' WATCHTOWER
    notice "'app_is_depreciated' WATCHTOWER returned $?"
    run_script 'app_is_depreciated' SAMBA
    notice "'app_is_depreciated' SAMBA returned $?"
    run_script 'app_is_depreciated' APPTHATDOESNOTEXIST
    notice "'app_is_depreciated' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_depreciated."
}
