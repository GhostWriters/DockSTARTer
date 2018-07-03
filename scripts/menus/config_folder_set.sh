#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config_folder_set() {

    local UNAME
    UNAME=$(id -un ${SUDO_USER})

    if (whiptail --title "Configs Location" --fb --yesno \
        "The default place for config files is: /home/${UNAME}/.docker/config\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Check if the folder exists?
        #TODO - Set permissions on the folder?
        SetVariableValue "DOCKERCONFDIR" "/home/${UNAME}/.docker/config" "${SCRIPTPATH}/compose/.env"
    else
        #TODO - Prompt for the location
        error "Currently not supported"
    fi
}
