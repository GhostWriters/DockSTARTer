#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Get the current TimeZone and ask if its ok or they want to change it.

user_group_set() {
    local UNAME
    UNAME=$(id -un "$(logname)")
    local UGROUP
    UGROUP=$(id -gn "$(logname)")
    local PID
    PID=$(id -u "$(logname)")
    local GID
    GID=$(id -g "$(logname)")

    #TODO CHECK IF EMBY ENABLED AND SET?
    # getent group video | cut -d: -f3

    if (whiptail --title "User and Group" --yesno \
            "The detected User is: ${UNAME}\\n \
            The detected Group is: ${UGROUP}\\n \
            This will be passed into the applications.\\n\\n \
            Would you like to accept this?" 11 78); then
        SetVariableValue "PUID" "${PID}" "${SCRIPTPATH}/compose/.env"
        SetVariableValue "PGID" "${GID}" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the username and group to be added.
        echo -e "${RED}Currently not supported${ENDCOLOR}"
        exit 1
    fi
}
