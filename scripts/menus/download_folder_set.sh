#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

download_folder_set() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Dowloads Location" --fb --yesno \
            "The default place for download files is: ${DETECTED_HOMEDIR}/Downloads\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        SetVariableValue 'DOWNLOADSDIR' "${DETECTED_HOMEDIR}/Downloads" "${SCRIPTPATH}/compose/.env"
    else
        run_menu 'input_prompt' 'DOWNLOADSDIR' "${DETECTED_HOMEDIR}/Downloads" "${SCRIPTPATH}/compose/.env"
    fi
}
