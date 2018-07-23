#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

download_folder_set() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Dowloads Location" --fb --yesno \
            "The default place for download files is: ${DETECTED_HOMEDIR}/Downloads\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 12 78); then
        reset || true
        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        run_script 'env_set' 'DOWNLOADSDIR' "${DETECTED_HOMEDIR}/Downloads"
    else
        run_menu 'input_prompt' 'DOWNLOADSDIR' "${DETECTED_HOMEDIR}/Downloads"
    fi
}
