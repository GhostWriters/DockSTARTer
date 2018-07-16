#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

media_folders_set() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Media Locations" --fb --yesno \
            "The default place for Media files is:\\n${DETECTED_HOMEDIR}/Books\\n${DETECTED_HOMEDIR}/Movies\\n${DETECTED_HOMEDIR}/Music\\n${DETECTED_HOMEDIR}/TV\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 17 78); then

        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        run_script 'env_set' 'MEDIADIR_BOOKS' "${DETECTED_HOMEDIR}/Books"
        run_script 'env_set' 'MEDIADIR_MOVIES' "${DETECTED_HOMEDIR}/Movies"
        run_script 'env_set' 'MEDIADIR_MUSIC' "${DETECTED_HOMEDIR}/Music"
        run_script 'env_set' 'MEDIADIR_TV' "${DETECTED_HOMEDIR}/TV"
    else
        run_menu 'input_prompt' 'MEDIADIR_BOOKS' "${DETECTED_HOMEDIR}/Books"
        run_menu 'input_prompt' 'MEDIADIR_MOVIES' "${DETECTED_HOMEDIR}/Movies"
        run_menu 'input_prompt' 'MEDIADIR_MUSIC' "${DETECTED_HOMEDIR}/Music"
        run_menu 'input_prompt' 'MEDIADIR_TV' "${DETECTED_HOMEDIR}/TV"
    fi
}
