#!/bin/bash

download_folder_set() {
    if (whiptail --title "Dowloads Location" --yesno \
        "The default place for download files is: /home/${UNAME}/Downloads\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 10 78) then
        
        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue "DOWNLOADSDIR" "/home/${UNAME}/Downloads" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the location
        echo -e "${RED}Currently not supported$ENDCOLOR"
    fi
}
