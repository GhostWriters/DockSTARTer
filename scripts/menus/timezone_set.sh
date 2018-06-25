#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

timezone_set() {
    # Get the current TimeZone and ask if its ok or they want to change it.
    local CURRENTTIMEZONE
    CURRENTTIMEZONE="$(cat /etc/timezone)"
    if (whiptail --title "Time Zone" --yesno --yes-button "OK" --no-button "Cancel" \
            "Your Current Time Zone is: ${CURRENTTIMEZONE} \\n \
            This will be passed into the applications.\\n\\n \
            If this is incorrect cancel now and change your system time zone!" 10 78); then
        SetVariableValue "TZ" "${CURRENTTIMEZONE}" "${SCRIPTPATH}/compose/.env"
    else
        exit 1
    fi
}
