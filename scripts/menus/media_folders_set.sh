#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

media_folders_set() {

    # local UNAME
    # UNAME=$(id -un ${SUDO_USER})


    echo
PUID=${SUDO_UID:-$UID}
echo "${PUID}"
UNAME=$(id -un "${PUID}")
echo "${UNAME}"
echo

    if (whiptail --title "Media Locations" --fb --yesno \
        "The default place for Media files is:\\n/home/${UNAME}/Books\\n/home/${UNAME}/Movies\\n/home/${UNAME}/Music\\n/home/${UNAME}/TV\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 15 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue 'MEDIADIR_BOOKS' "/home/${UNAME}/Books" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_MOVIES' "/home/${UNAME}/Movies" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_MUSIC' "/home/${UNAME}/Music" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_TV' "/home/${UNAME}/TV" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt.sh' 'MEDIADIR_BOOKS' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt.sh' 'MEDIADIR_MOVIES' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt.sh' 'MEDIADIR_MUSIC' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt.sh' 'MEDIADIR_TV' "${SCRIPTPATH}/compose/.env"
    fi
}
