#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config_folder_set() {
    if (whiptail --title "Configs Location" --fb --yesno \
            "The default place for config files is: ${SHOMEDIR}/.docker/config\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Check if the folder exists?
        #TODO - Set permissions on the folder?
        SetVariableValue 'DOCKERCONFDIR' "${SHOMEDIR}/.docker/config" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt' 'DOCKERCONFDIR' "${SCRIPTPATH}/compose/.env"
    fi
}
