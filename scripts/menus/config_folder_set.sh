#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config_folder_set() {
    if (whiptail --title "Configs Location" --yesno \
            "The default place for config files is: /home/${UNAME}/.docker/config\\n \
            This will be passed into the applications.\\n\\n \
            Would you like to accept this?" 10 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue "DOCKERCONFDIR" "/home/${UNAME}/.docker/config" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the location
        echo -e "${RED}Currently not supported${ENDCOLOR}"
    fi
}
