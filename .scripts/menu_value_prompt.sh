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
    local HomeValue="Home Value"
    local SystemValue="System Value"
    local PreviousValue="Previous Value"

    local -a ValidOptions=("${CurrentValue}" "${DefaultValue}" "${HomeValue}" "${SystemValue}" "${PreviousValue}")
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
            ;;
        "${APPNAME}__PORT_"*)
            ValueDescription='\n\n Must be an unused port between 0 and 65535.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            ;;
        "${APPNAME}__RESTART")
            ValueDescription='\n\n Restart is usually unless-stopped but can also be no, always, or on-failure.'
            Value["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
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
    local DescriptionHeading
    DescriptionHeading="\nApplication: \Zr${AppName}\ZR\n       File: \Zr${VarFile}\ZR\n   Variable: \Zr${CleanVarName}\ZR\n"
    while true; do
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
                local -i result=0
                Value["${CurrentValue}"]="$(validate_value "${VarName}" "${Value["${CurrentValue}"]}" "Save ${VarName}")" || result=$?
                if [[ ${result} ]]; then # Value is valid, save it and exit
                    if run_script 'question_prompt' N "${DescriptionHeading}      Value: \Zr${Value["${CurrentValue}"]}\ZR\n" "Save Variable" "" "Save" "Back"; then
                        run_script 'env_set_literal' "${VarName}" "${Value["${CurrentValue}"]}"
                        return 0
                    fi
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

validate_value() {
    local VarName=${1-}
    local Input=${2-}
    local Title=${3-}
    if [[ ${Input} == *"$"* ]]; then
        # Value contains a '$', assume it uses variable interpolation and allow it
        printf '%s' "${Input}"
        return 0
    fi
    case "${VarName}" in
        "${APPNAME}__ENABLED")
            printf '%s' "${Input}"
            if [[ ${Input} == true ]] || [[ ${Input} == false ]]; then
                return 0
            else
                dialog --title "${Title}" --msgbox "${Input} is not true or false. Please try setting ${VarName} again." 0 0
                return 1
            fi
            ;;
        "${APPNAME}__NETWORK_MODE")
            printf '%s' "${Input}"
            case "${Input}" in
                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                    return 0
                    ;;
                *)
                    dialog --title "${Title}" --msgbox "${Input} is not a valid network mode. Please try setting ${VarName} again." 0 0
                    return 1
                    ;;
            esac
            ;;
        "${APPNAME}__PORT_"*)
            printf '%s' "${Input}"
            if [[ ${Input} =~ ^[0-9]+$ ]] || [[ ${Input} -ge 0 ]] || [[ ${Input} -le 65535 ]]; then
                return 0
            else
                dialog --title "${Title}" --msgbox "${Input} is not a valid port. Please try setting ${VarName} again." 0 0
                return 1
            fi
            ;;
        "${APPNAME}__RESTART")
            printf '%s' "${Input}"
            case "${Input}" in
                "no" | "always" | "on-failure" | "unless-stopped")
                    return 0
                    ;;
                *)
                    dialog --title "${Title}" --msgbox "${Input} is not a valid restart value. Please try setting ${VarName} again." 0 0
                    return 1
                    ;;
            esac
            ;;
        "${APPNAME}__VOLUME_"*)
            if [[ ${Input} == "/" ]]; then
                dialog --title "${Title}" --msgbox "Cannot use / for ${VarName}. Please select another folder." 0 0
                printf '%s' "${Input}"
                return 1
            elif [[ ${Input} == ~* ]]; then
                local CORRECTED_DIR="${DETECTED_HOMEDIR}${Input#*~}"
                if run_script 'question_prompt' Y "Cannot use the ~ shortcut in ${VarName}. Would you like to use ${CORRECTED_DIR} instead?" "${Title}"; then
                    dialog --title "${Title}" --msgbox "Returning to the previous menu to confirm selection." 0 0
                    printf '%s' "${CORRECTED_DIR}"
                    return 1
                else
                    dialog --title "${Title}" --msgbox "Cannot use the ~ shortcut in ${VarName}. Please select another folder." 0 0
                    printf '%s' "${Input}"
                    return 1
                fi
            elif [[ -d ${Input} ]]; then
                if run_script 'question_prompt' Y "Would you like to set permissions on ${Input} ?" "${Title}"; then
                    run_script_dialog "Settings Permissions" "${Input}" "" \
                        'set_permissions' "${Input}"
                fi
                printf '%s' "${Input}"
                return 0
            else
                if run_script 'question_prompt' Y "${Input} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                    {
                        mkdir -p "${Input}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${Input}\""
                        run_script 'set_permissions' "${Input}"
                    } | dialog_pipe "Creating folder and settings permissions" "${Input}"
                    dialog --title "${Title}" --msgbox "${Input} folder was created successfully." 0 0
                    printf '%s' "${Input}"
                    return 0
                else
                    dialog --title "${Title}" --msgbox "${Input} is not a valid path. Please try setting ${VarName} again." 0 0
                    printf '%s' "${Input}"
                    return 1
                fi
            fi
            ;;
        P[GU]ID)
            printf '%s' "${Input}"
            if [[ ${Input} == "0" ]]; then
                if run_script 'question_prompt' Y "Running as root is not recommended. Would you like to select a different ID?" "${Title}" "Y"; then
                    return 1
                else
                    return 0
                fi
            elif [[ ${Input} =~ ^[0-9]+$ ]]; then
                return 0
            else
                dialog --stderr --title "${Title}" --msgbox "${Input} is not a valid ${VarName}. Please try setting ${VarName} again." 0 0
                return 1
            fi
            ;;
        *)
            printf '%s' "${Input}"
            return 0
            ;;
    esac
}

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
