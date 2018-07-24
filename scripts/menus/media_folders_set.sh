#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

media_folders_set() {

    local ENVBOOKS
    ENVBOOKS=$(run_script 'env_get' 'MEDIADIR_BOOKS')
    ENVBOOKS="${ENVBOOKS:-"${DETECTED_HOMEDIR}/Books"}"

    local ENVMOVIES
    ENVMOVIES=$(run_script 'env_get' 'MEDIADIR_MOVIES')
    ENVMOVIES="${ENVMOVIES:-"${DETECTED_HOMEDIR}/Movies"}"

    local ENVMUSIC
    ENVMUSIC=$(run_script 'env_get' 'MEDIADIR_MUSIC')
    ENVMUSIC="${ENVMUSIC:-"${DETECTED_HOMEDIR}/Music"}"

    local ENVTV
    ENVTV=$(run_script 'env_get' 'MEDIADIR_TV')
    ENVTV="${ENVTV:-"${DETECTED_HOMEDIR}/TV"}"

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && (whiptail --title "Media Locations" --fb --yesno \
            "The detected .env parameter or suggested location for Media files is:\\nBooks = ${ENVBOOKS}\\nMovies = ${ENVMOVIES}\\nMusic = ${ENVMUSIC}\\nTV = ${ENVTV}\\n\\nThis will be passed into the applications.\\n\\nWould you like to accept this?" 17 78); then
        reset || true
        #TODO - Should we check if the folder exists?
        #TODO - Should we set permissions on the folder?
        run_script 'env_set' 'MEDIADIR_BOOKS' "${ENVBOOKS}"
        run_script 'env_set' 'MEDIADIR_MOVIES' "${ENVMOVIES}"
        run_script 'env_set' 'MEDIADIR_MUSIC' "${ENVMUSIC}"
        run_script 'env_set' 'MEDIADIR_TV' "${ENVTV}"
    else
        run_menu 'input_prompt' 'MEDIADIR_BOOKS' "${ENVBOOKS}"
        run_menu 'input_prompt' 'MEDIADIR_MOVIES' "${ENVMOVIES}"
        run_menu 'input_prompt' 'MEDIADIR_MUSIC' "${ENVMUSIC}"
        run_menu 'input_prompt' 'MEDIADIR_TV' "${ENVTV}"
    fi
}
