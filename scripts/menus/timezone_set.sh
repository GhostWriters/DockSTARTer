#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

timezone_set() {
    # Get the current TimeZone and ask if its ok or they want to change it.
    local CURRENTTIMEZONE
    CURRENTTIMEZONE="$(cat /etc/timezone)"

    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        run_script 'env_set' 'TZ' "${CURRENTTIMEZONE}"
    else
        whiptail --title "Time Zone" --fb --yesno --yes-button "OK" --no-button "Cancel" \
            "Your Current Time Zone is: ${CURRENTTIMEZONE} \\nThis will be passed into the applications.\\n\\nIf this is incorrect cancel now and change your system time zone!" 12 78

        run_script 'env_set' 'TZ' "${CURRENTTIMEZONE}"
    fi
}
