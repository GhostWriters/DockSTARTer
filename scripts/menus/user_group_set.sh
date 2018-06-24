#!/bin/bash

# Get the current TimeZone and ask if its ok or they want to change it.

user_group_set() {
    UNAME=$(id -un ${SUDO_USER})
    UGROUP=$(id -gn ${SUDO_USER})
    PID=$(id -u ${SUDO_USER})
    GID=$(id -g ${SUDO_USER})

    #TODO CHECK IF EMBY ENABLED AND SET? 
    # getent group video | cut -d: -f3

    if (whiptail --title "User and Group" --yesno \
        "The detected User is: ${UNAME}\\nThe detected Group is: ${UGROUP}\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 11 78) then
        SetVariableValue "PUID" "${PID}" "${SCRIPTPATH}/compose/.env"
        SetVariableValue "PGID" "${GID}" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the username and group to be added.
        echo -e "${RED}Currently not supported$ENDCOLOR"
        exit 1
    fi
}
