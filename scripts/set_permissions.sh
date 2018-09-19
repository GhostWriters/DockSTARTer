#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

set_permissions() {
    local CH_PATH
    CH_PATH=${1:-$SCRIPTPATH}
    local CH_PUID
    CH_PUID=${2:-$DETECTED_PUID}
    local CH_PGID
    CH_PGID=${3:-$DETECTED_PGID}
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        info "Overriding PUID and PGID for Travis."
        CH_PUID=${DETECTED_UNAME}
        CH_PGID=${DETECTED_UGROUP}
    fi
    info "Taking ownership of ${CH_PATH} for user ${CH_PUID} and group ${CH_PGID}"
    chown -R "${CH_PUID}":"${CH_PGID}" "${CH_PATH}" > /dev/null 2>&1 || true
    info "Setting file and folder permissions in ${CH_PATH}"
    chmod -R a=,a+rX,u+w,g+w "${CH_PATH}" > /dev/null 2>&1 || true
    chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
}
