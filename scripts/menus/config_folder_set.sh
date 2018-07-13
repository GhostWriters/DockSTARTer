#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config_folder_set() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Configs Location" --fb --yesno \
            "The default place for config files is: ${DETECTED_HOMEDIR}/.docker/config\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Check if the folder exists?
        #TODO - Set permissions on the folder?
        SetVariableValue 'DOCKERCONFDIR' "${DETECTED_HOMEDIR}/.docker/config" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt' 'DOCKERCONFDIR' "${DETECTED_HOMEDIR}/.docker/config" "${SCRIPTPATH}/compose/.env"
    fi
}
