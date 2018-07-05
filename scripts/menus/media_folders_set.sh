#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

media_folders_set() {
    if (whiptail --title "Media Locations" --fb --yesno \
            "The default place for Media files is:\\n${SHOMEDIR}/Books\\n${SHOMEDIR}/Movies\\n${SHOMEDIR}/Music\\n${SHOMEDIR}/TV\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 15 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue 'MEDIADIR_BOOKS' "${SHOMEDIR}/Books" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_MOVIES' "${SHOMEDIR}/Movies" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_MUSIC' "${SHOMEDIR}/Music" "${SCRIPTPATH}/compose/.env"
        SetVariableValue 'MEDIADIR_TV' "${SHOMEDIR}/TV" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt' 'MEDIADIR_BOOKS' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt' 'MEDIADIR_MOVIES' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt' 'MEDIADIR_MUSIC' "${SCRIPTPATH}/compose/.env"
        run_menu 'input_prompt' 'MEDIADIR_TV' "${SCRIPTPATH}/compose/.env"
    fi
}
