#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

app_is_nondeprecated() {
    local APPNAME=${1-}
    local LABELS_FILE
    LABELS_FILE="$(run_script 'app_instance_file' "${APPNAME}" ".labels.yml")"
    local APP_DEPRECATED
    if [[ -f ${LABELS_FILE} ]]; then
        APP_DEPRECATED="$(grep --color=never -Po "\scom\.dockstarter\.appinfo\.deprecated: \K.*" "${LABELS_FILE}" | sed -E 's/^([^"].*[^"])$/"\1"/' | xargs || echo false)"
    fi
    if [[ ${APP_DEPRECATED-} == "false" ]]; then
        return 0
    else
        return 1
    fi
}

test_app_is_nondeprecated() {
    run_script 'app_is_nondeprecated' WATCHTOWER
    notice "'app_is_nondeprecated' WATCHTOWER returned $?"
    run_script 'app_is_nondeprecated' SAMBA
    notice "'app_is_nondeprecated' SAMBA returned $?"
    run_script 'app_is_nondeprecated' APPTHATDOESNOTEXIST
    notice "'app_is_nondeprecated' APPTHATDOESNOTEXIST returned $?"
    #warn "CI does not test app_is_nondeprecated."
}
