#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

config_folder_set() {

    local ENVDOCCONFDIR
    ENVDOCCONFDIR=$(run_script 'env_get' 'DOCKERCONFDIR')
    ENVDOCCONFDIR="${ENVDOCCONFDIR:-"${DETECTED_HOMEDIR}/.docker/config"}"

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Configs Location" --fb --yesno \
            "The detected .env parameter or suggested place for config files is:\\n${ENVDOCCONFDIR}\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 14 78); then
        reset || true
        #TODO - Check if the folder exists?
        #TODO - Set permissions on the folder?
        run_script 'env_set' 'DOCKERCONFDIR' "${ENVDOCCONFDIR}"
    else
        run_menu 'input_prompt' 'DOCKERCONFDIR' "${ENVDOCCONFDIR}"
    fi
}
