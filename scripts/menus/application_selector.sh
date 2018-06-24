#!/bin/bash

application_selector() {
    
    run_script 'menu_app_helper'

    # Might need to be adjusted if more applications are added
    LINES=27
    COLUMNS=92
    NETLINES=20

    tempfile=$(mktemp)
    trap 'rm -f "$tempfile"' EXIT

    whiptail --title "Application Selector" --checklist --separate-output "Choose which apps you would like to install:" $LINES $COLUMNS $NETLINES "${SupportedAppDescr[@]}" 2>"$tempfile"

    readonly EXITSTATUS=$?
    if [[ ${EXITSTATUS} == 0 ]]; then

        #TODO - Ask if the user wants the disable the other apps in .env

        while read -r choice; do
            SetVariableValue "$(echo "${choice^^}" | tr -d ' ')_ENABLED" "true" "${SCRIPTPATH}/compose/.env"
        done < "$tempfile"
    else
        echo
        sleep 1
        exit 0
    fi
}
