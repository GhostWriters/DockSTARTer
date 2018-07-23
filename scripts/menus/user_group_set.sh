#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

user_group_set() {
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        run_script 'env_set' 'PUID' "${DETECTED_PUID}"
        run_script 'env_set' 'PGID' "${DETECTED_PGID}"
    else
        whiptail --title "User and Group"  --fb --yesno --yes-button "OK" --no-button "Cancel" \
            "The detected User is: ${DETECTED_UNAME}\\nThe detected Group is: ${DETECTED_UGROUP}\\n\\nThis will be passed into the applications.\\n\\nPlease cancel if this is incorrect or adjust .env file manually after." 14 78
        reset || true
        run_script 'env_set' 'PUID' "${DETECTED_PUID}"
        run_script 'env_set' 'PGID' "${DETECTED_PGID}"
    fi
}
