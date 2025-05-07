#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local VarName=${1-}
    local Title="Edit Variable"
    if [[ ${CI-} == true ]]; then
        return
    fi

    local APPNAME
    APPNAME=$(run_script 'varname_to_appname' "${VarName}")
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")
    local CleanVarName="${VarName}"
    local VarFile="${COMPOSE_ENV}"
    local DefaultVarFile=${COMPOSE_ENV_DEFAULT_FILE}
    if [[ -n ${APPNAME-} ]]; then
        local APP_FOLDER="${SCRIPTPATH}/compose/.apps/${appname}"
        if [[ ${VarName} == *":"* ]]; then
            CleanVarName=${VarName#*:}
            VarFile="${APP_ENV_FOLDER}/${appname}.env"
            DefaultVarFile="${APP_FOLDER}/${appname}.env"
        else
            DefaultVarFile="${APP_FOLDER}/.env"
        fi
    fi
    local ValueDescription
    ValueDescription=$(value_description "${VarName}")

    local -A Value
    local CurrentValue="Current Value"
    local DefaultValue="Default Value"
    local HomeValue="Home Folder"
    local SystemValue="System Value"
    local PreviousValue="Previous Value"

    local -a ValidOptions=(
        "${CurrentValue}"
        "${DefaultValue}"
        "Bridge Network"
        "Host Network"
        "No Network"
        "Use Gluetun"
        "Use Privoxy"
        "Unless Stopped"
        "No Restart"
        "Always"
        "On Failure"
        "${HomeValue}"
        "Mount Folder"
        "${SystemValue}"
        "${PreviousValue}"
    )
    local ValidOptionsRegex
    {
        IFS='|'
        ValidOptionsRegex="${ValidOptions[*]}"
    }
    Value["${PreviousValue}"]=$(run_script 'env_get_literal' "${VarName}")
    Value["${CurrentValue}"]="${Value["${PreviousValue}"]}"
    case "${VarName}" in
        DOCKER_GID)
            ValueDescription="\n\n This should be the Docker group ID. If you are unsure, select ${SystemValue}."
            Value["${SystemValue}"]="'$(cut -d: -f3 < <(getent group docker))'"
            ;;
        DOCKER_HOSTNAME)
            ValueDescription="\n\n This should be your system hostname. If you are unsure, select ${SystemValue}."
            Value["${SystemValue}"]="'${HOSTNAME}'"
            ;;
        DOCKER_VOLUME_CONFIG)
            Value["${HomeValue}"]="'${DETECTED_HOMEDIR}/.config/appdata'"
            ;;
        DOCKER_VOLUME_STORAGE)
            Value["${HomeValue}"]="'${DETECTED_HOMEDIR}/storage'"
            Value["Mount Folder"]="'/mnt/storage'"
            ;;
        LAN_NETWORK)
            ValueDescription='\n\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more.'
            Value["${SystemValue}"]="'$(run_script 'detect_lan_network')'"
            ;;
        PGID)
            ValueDescription="\n\n This should be your user group ID. If you are unsure, select ${SystemValue}."
            Value["${SystemValue}"]="'${DETECTED_PGID}'"
            ;;
        PUID)
            ValueDescription="\n\n This should be your user account ID. If you are unsure, select ${SystemValue}."
            Value["${SystemValue}"]="'${DETECTED_PUID}'"
            ;;
        TZ)
            ValueDescription='\n\n If this is not the correct timezone please exit and set your system timezone.'
            Value["${SystemValue}"]="'$(cat /etc/timezone)'"
            ;;
        "${APPNAME}__ENABLED")
            ValueDescription='\n\n Must be true or false.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
        "${APPNAME}__NETWORK_MODE")
            ValueDescription='\n\n Network Mode is usually left blank but can also be bridge, host, none, service:<appname>, or container:<appname>.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            Value["Bridge Network"]="'bridge'"
            Value["Host Network"]="'host'"
            Value["No Network"]="'none'"
            Value["Use Gluetun"]="'service:gluetun'"
            Value["Use Privoxy"]="'service:privoxy'"
            ;;
        "${APPNAME}__PORT_"*)
            ValueDescription='\n\n Must be an unused port between 0 and 65535.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
        "${APPNAME}__RESTART")
            ValueDescription='\n\n Restart is usually unless-stopped but can also be no, always, or on-failure.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            Value["Unless Stopped"]="'unless-stopped'"
            Value["No Restart"]="'no'"
            Value["Always"]="'always'"
            Value["On Failure"]="'on-failure'"
            ;;
        "${APPNAME}__TAG")
            ValueDescription='\n\n Tag is usually latest but can also be other values based on the image.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
        "${APPNAME}__VOLUME_"*)
            ValueDescription='\n\n If the directory selected does not exist we will attempt to create it.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
        *)
            ValueDescription=""
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
    esac
    if [[ -n ${Value["${SystemValue}"]-} ]]; then
        ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
    fi
     while true; do
        # editorconfig-checker-disable
        local DescriptionHeading="

Application: \Zr${AppName}\Zn
       File: \Zr${VarFile}\Zn
   Variable: \Zr${CleanVarName}\Zn
      Value: \Zr${Value["${CurrentValue}"]-S}\Zn

"
        # editorconfig-checker-enable
        local -a ValueOptions=()
        for Option in "${ValidOptions[@]}"; do
            if [[ -n ${Value[$Option]-} ]]; then
                ValueOptions+=("${Option}" "${Value[$Option]}")
            fi
        done

        local -i SelectValueDialogButtonPressed=0
        local SelectedValue
        local -a SelectValueDialog=(
            --stdout
            --begin 2 2
            --colors
            --no-visit-items
            --ok-label "Select"
            --extra-label "Edit"
            --cancel-label "Done"
            --title "${Title}"
            --inputmenu "${DescriptionHeading}\nWhat would you like set for ${CleanVarName}?${ValueDescription}"
            $((LINES - 7)) $((COLUMNS - 5)) 0
            "${ValueOptions[@]}"
        )
        SelectValueDialogButtonPressed=0
        SelectedValue=$(dialog "${SelectValueDialog[@]}") || SelectValueDialogButtonPressed=$?

        case ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} in
            OK) # SELECT button
                if [[ ${SelectedValue} =~ ${ValidOptionsRegex} ]]; then
                    if [[ -n ${Value[$SelectedValue]-} ]]; then
                        Value["${CurrentValue}"]="${Value["$SelectedValue"]}"
                    else
                        error "Unset value '${SelectedValue}'"
                    fi
                else
                    error "Invalid option '${SelectedValue}'"
                fi
                ;;
            EXTRA) # EDIT button
                dialog --title "${Title}" --msgbox "Manual editing of values is not implemented yet." 0 0
                ;;
            CANCEL | ESC) # DONE button
                local ValueValid
                if [[ ${Value["${CurrentValue}"]} == *"$"* ]]; then
                    # Value contains a '$', assume it uses variable interpolation and allow it
                    ValueValid="true"
                else
                    local StrippedValue="${Value["${CurrentValue}"]}"
                    # Strip comments from the value
                    #StrippedValue="$(sed -E "s/('([^']|'')*'|\"([^\"]|\"\")*\")|(#.*)//g" <<< "${StrippedValue}")"
                    #dialog --colors --title "${Title}" --msgbox "Original Value=\Zr${Value["${CurrentValue}"]}\ZR\nStripped Value=\Zr${StrippedValue}\ZR" 0 0
                    # Unqauote the value
                    StrippedValue="$(sed -E "s|^(['\"])(.*)\1$|\2|g" <<< "${StrippedValue}")"

                    case "${VarName}" in
                        "${APPNAME}__ENABLED")
                            if [[ ${StrippedValue} == true ]] || [[ ${StrippedValue} == false ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not true or false. Please try setting ${CleanVarName} again." 0 0
                            fi
                            ;;
                        "${APPNAME}__NETWORK_MODE")
                            case "${StrippedValue}" in
                                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not a valid network mode. Please try setting ${CleanVarName} again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__PORT_"*)
                            printf '%s' "${Value["${CurrentValue}"]}"
                            if [[ ${StrippedValue} =~ ^[0-9]+$ ]] || [[ ${StrippedValue} -ge 0 ]] || [[ ${StrippedValue} -le 65535 ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not a valid port. Please try setting ${CleanVarName} again." 0 0
                            fi
                            ;;
                        "${APPNAME}__RESTART")
                            case "${StrippedValue}" in
                                "no" | "always" | "on-failure" | "unless-stopped")
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not a valid restart value. Please try setting ${CleanVarName} again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__VOLUME_"*)
                            if [[ ${StrippedValue} == "/" ]]; then
                                dialog --title "${Title}" --msgbox "Cannot use / for ${CleanVarName}. Please select another folder." 0 0
                                ValueValid="false"
                            elif [[ ${StrippedValue} == ~* ]]; then
                                local CORRECTED_DIR="${DETECTED_HOMEDIR}${Value["${CurrentValue}"]#*~}"
                                if run_script 'question_prompt' Y "Cannot use the ~ shortcut in ${CleanVarName}. Would you like to use ${CORRECTED_DIR} instead?" "${Title}"; then
                                    Value["${CurrentValue}"]="${CORRECTED_DIR}"
                                    ValueValid="false"
                                    dialog --title "${Title}" --msgbox "Returning to the previous menu to confirm selection." 0 0
                                else
                                    ValueValid="false"
                                    dialog --title "${Title}" --msgbox "Cannot use the ~ shortcut in ${CleanVarName}. Please select another folder." 0 0
                                fi
                            elif [[ -d ${StrippedValue} ]]; then
                                if run_script 'question_prompt' Y "Would you like to set permissions on ${Value["${CurrentValue}"]} ?" "${Title}"; then
                                    run_script_dialog "Settings Permissions" "${StrippedValue}" "" \
                                        'set_permissions' "${StrippedValue}"
                                fi
                                ValueValid="true"
                            else
                                if run_script 'question_prompt' Y "${Value["${CurrentValue}"]} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                                    {
                                        mkdir -p "${StrippedValue}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${StrippedValue}\""
                                        run_script 'set_permissions' "${StrippedValue}"
                                    } | dialog_pipe "Creating folder and settings permissions" "${Value["${CurrentValue}"]}"
                                    dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} folder was created successfully." 0 0
                                    ValueValid="true"
                                else
                                    dialog --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not a valid path. Please try setting ${CleanVarName} again." 0 0
                                    ValueValid="false"
                                fi
                            fi
                            ;;
                        P[GU]ID)
                            if [[ ${StrippedValue} == "0" ]]; then
                                if run_script 'question_prompt' Y "Running as root is not recommended. Would you like to select a different ID?" "${Title}" "Y"; then
                                    ValueValid="false"
                                else
                                    ValueValid="true"
                                fi
                            elif [[ ${StrippedValue} =~ ^[0-9]+$ ]]; then
                                ValueValid="true"
                            else
                                dialog --stderr --title "${Title}" --msgbox "${Value["${CurrentValue}"]} is not a valid ${VarName}. Please try setting ${VarName} again." 0 0
                                ValueValid="false"
                            fi
                            ;;
                        *)
                            ValueValid="true"
                            ;;
                    esac
                fi
                if ${ValueValid} && run_script 'question_prompt' N "${DescriptionHeading}" "Save Variable" "" "Save" "Back"; then
                    # Value is valid, save it and exit
                    run_script 'env_set_literal' "${VarName}" "${Value["${CurrentValue}"]}"
                    return 0
                fi
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} ]]; then
                    clear && fatal "Unexpected dialog button '${DIALOG_BUTTONS[SelectValueDialogButtonPressed]}' pressed."
                else
                    clear && fatal "Unexpected dialog button value' ${SelectValueDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
