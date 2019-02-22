#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

config_globals() {
    info "Configuring global .env variables."
    local APPNAME
    APPNAME="Globals"
    local VARNAMES
    VARNAMES=(TZ DOCKERHOSTNAME PUID PGID DOCKERCONFDIR DOWNLOADSDIR MEDIADIR_BOOKS MEDIADIR_COMICS MEDIADIR_MOVIES MEDIADIR_MUSIC MEDIADIR_TV DOCKERSHAREDDIR)
    local APPVARS
    APPVARS=$(for v in "${VARNAMES[@]}"; do echo "${v}=$(run_script 'env_get' "${v}")"; done)

    local ANSWER
    set +e
    ANSWER=$(
        whiptail --fb --clear --title "DockSTARTer" --defaultno --yesno "Would you like to keep these settings for ${APPNAME}?\\n\\n${APPVARS}" 0 0 3>&1 1>&2 2>&3
        echo $?
    )
    set -e
    if [[ ${ANSWER} != 0 ]]; then
        while IFS= read -r line; do
            SET_VAR=${line%%=*}
            run_script 'menu_value_prompt' "${SET_VAR}" || return 1
        done < <(echo "${APPVARS}")
    fi
}
