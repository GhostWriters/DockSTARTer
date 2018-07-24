#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

download_folder_set() {

    local ENVDOWNLOADSDIR
    ENVDOWNLOADSDIR=$(run_script 'env_get' 'DOWNLOADSDIR')
    ENVDOWNLOADSDIR="${ENVDOWNLOADSDIR:-"${DETECTED_HOMEDIR}/Downloads"}"

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Dowloads Location" --fb --yesno \
            "The detected .env parameter or suggested location for download files is:\\n${ENVDOWNLOADSDIR}\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 14 78); then
        reset || true
        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        run_script 'env_set' 'DOWNLOADSDIR' "${ENVDOWNLOADSDIR}"
    else
        run_menu 'input_prompt' 'DOWNLOADSDIR' "${ENVDOWNLOADSDIR}"
    fi
}
