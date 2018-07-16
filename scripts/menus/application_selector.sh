#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

application_selector() {
    SupportedAppDescr=()
    run_script 'menu_app_helper'

    # Might need to be adjusted if more applications are added
    local LINES
    LINES=$(stty size | cut '-d ' -f1)
    LINES=$((LINES<27?LINES:27))

    local COLUMNS
    COLUMNS=$(stty size | cut '-d ' -f2)
    COLUMNS=$((COLUMNS<92?COLUMNS:92))

    local NETLINES
    NETLINES=$((LINES-10))

    local tempfile
    tempfile=$(mktemp)

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        whiptail --title "Application Selector" --fb --checklist --separate-output "Choose which apps you would like to install:" --fb ${LINES} ${COLUMNS} ${NETLINES} "${SupportedAppDescr[@]}" 2>"${tempfile}"
    fi
    #TODO - Ask if the user wants the disable the other apps in .env

    while read -r choice; do
        run_script 'env_set' "$(echo "${choice^^}" | tr -d ' ')_ENABLED" 'true'
    done < "${tempfile}"

    rm -f "${tempfile}"
}
