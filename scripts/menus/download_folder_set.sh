#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

download_folder_set() {

    local UNAME
    UNAME=$(id -un ${SUDO_USER})

    if (whiptail --title "Dowloads Location" --fb --yesno \
        "The default place for download files is: /home/${UNAME}/Downloads\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue "DOWNLOADSDIR" "/home/${UNAME}/Downloads" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt.sh' 'DOWNLOADSDIR' "${SCRIPTPATH}/compose/.env"
    fi
}
