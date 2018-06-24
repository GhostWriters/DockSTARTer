#!/bin/bash

timezone_set() {
    # Get the current TimeZone and ask if its ok or they want to change it.
    readonly CURRENTTIMEZONE="$(cat /etc/timezone)"
    if (whiptail --title "Time Zone" --yesno --yes-button "OK" --no-button "Cancel" \
        "Your Current Time Zone is: ${CURRENTTIMEZONE} \\nThis will be passed into the applications.\\n\\nIf this is incorrect cancel now and change your system time zone!" 10 78) then
        SetVariableValue "TZ" "${CURRENTTIMEZONE}" "${SCRIPTPATH}/compose/.env"
    else
        exit 1
    fi
}
