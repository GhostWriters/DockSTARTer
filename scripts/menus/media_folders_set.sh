#!/bin/bash

media_folders_set() {
    if (whiptail --title "Media Locations" --yesno \
        "The default place for Media files is:\\n/home/${UNAME}/Movies\\n/home/${UNAME}/Music\\n/home/${UNAME}/TV\\n/home/${UNAME}/Books\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 15 78) then
        
        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue "MEDIADIR_BOOKS" "/home/${UNAME}/Books" "${SCRIPTPATH}/compose/.env"
        SetVariableValue "MEDIADIR_MOVIES" "/home/${UNAME}/Movies" "${SCRIPTPATH}/compose/.env"
        SetVariableValue "MEDIADIR_MUSIC" "/home/${UNAME}/Music" "${SCRIPTPATH}/compose/.env"
        SetVariableValue "MEDIADIR_TV" "/home/${UNAME}/TV" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the location
        echo -e "${RED}Currently not supported$ENDCOLOR"
        exit 1
    fi
}
