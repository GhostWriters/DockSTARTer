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
    chown -R "${CH_PUID}":"${CH_PGID}" "${CH_PATH}"
    info "Setting folder permissions in ${CH_PATH} to 755"
    find "${CH_PATH}" -type d -print0 | xargs -0 chmod 755
    info "Setting file permissions in ${CH_PATH} to 644"
    find "${CH_PATH}" -type f -print0 | xargs -0 chmod 644
}
