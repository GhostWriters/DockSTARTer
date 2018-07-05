#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

download_folder_set() {
    if (whiptail --title "Dowloads Location" --fb --yesno \
            "The default place for download files is: ${SHOMEDIR}/Downloads\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue 'DOWNLOADSDIR' "${SHOMEDIR}/Downloads" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt' 'DOWNLOADSDIR' "${SCRIPTPATH}/compose/.env"
    fi
}
