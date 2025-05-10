#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local VarName=${1-}
    local Title="Edit Variable"
    if [[ ${CI-} == true ]]; then
        return
    fi

    local ColorHeading='\Zr'
    local ColorHighlight='\Zr'
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

    local CurrentValue="Current Value"
    local DefaultValue="Default Value"
    local HomeValue="Home Folder"
    local SystemValue="System Value"
    local PreviousValue="Previous Value"

    local ValueDescription=""
    local -A OptionValue=()
    OptionValue["${PreviousValue}"]=$(run_script 'env_get_literal' "${VarName}")
    OptionValue["${CurrentValue}"]="${OptionValue["${PreviousValue}"]}"

    local -a PossibleOptions=("${CurrentValue}")
    case "${VarName}" in
        DOCKER_GID)
            ValueDescription="\n\n This should be the Docker group ID. If you are unsure, select ${SystemValue}."
            OptionValue+=(
                ["${SystemValue}"]="'$(cut -d: -f3 < <(getent group docker))'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        DOCKER_HOSTNAME)
            ValueDescription="\n\n This should be your system hostname. If you are unsure, select ${SystemValue}."
            OptionValue+=(
                ["${SystemValue}"]="'${HOSTNAME}'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        DOCKER_VOLUME_CONFIG)
            OptionValue+=(
                ["${HomeValue}"]="'${DETECTED_HOMEDIR}/.config/appdata'"
            )
            PossibleOptions+=(
                "${HomeValue}"
            )
            ;;
        DOCKER_VOLUME_STORAGE)
            OptionValue+=(
                ["${HomeValue}"]="'${DETECTED_HOMEDIR}/storage'"
                ["Mount Folder"]="'/mnt/storage'"
            )
            PossibleOptions+=(
                "${HomeValue}"
                "Mount Folder"
            )
            ;;
        GLOBAL_LAN_NETWORK)
            ValueDescription='\n\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more.'
            OptionValue+=(
                ["${SystemValue}"]="'$(run_script 'detect_lan_network')'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        PGID)
            ValueDescription="\n\n This should be your user group ID. If you are unsure, select ${SystemValue}."
            OptionValue+=(
                ["${SystemValue}"]="'${DETECTED_PGID}'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        PUID)
            ValueDescription="\n\n This should be your user account ID. If you are unsure, select ${SystemValue}."
            OptionValue+=(
                ["${SystemValue}"]="'${DETECTED_PUID}'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        TZ)
            ValueDescription='\n\n If this is not the correct timezone please exit and set your system timezone.'
            OptionValue+=(
                ["${SystemValue}"]="'$(cat /etc/timezone)'"
            )
            PossibleOptions+=(
                "${SystemValue}"
            )
            ;;
        "${APPNAME}__ENABLED")
            ValueDescription='\n\n Must be true or false.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValue}"
            )
            ;;
        "${APPNAME}__NETWORK_MODE")
            ValueDescription='\n\n Network Mode is usually left blank but can also be bridge, host, none, service:<appname>, or container:<appname>.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
                ["Bridge Network"]="'bridge'"
                ["Host Network"]="'host'"
                ["No Network"]="'none'"
                ["Use Gluetun"]="'service:gluetun'"
                ["Use Privoxy"]="'service:privoxy'"
            )
            PossibleOptions+=(
                "${DefaultValue}"
                "Bridge Network"
                "Host Network"
                "No Network"
                "Use Gluetun"
                "Use Privoxy"
            )
            ;;
        "${APPNAME}__PORT_"*)
            ValueDescription='\n\n Must be an unused port between 0 and 65535.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValue}"
            )
            ;;
        "${APPNAME}__RESTART")
            ValueDescription='\n\n Restart is usually unless-stopped but can also be no, always, or on-failure.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
                ["Restart Unless Stopped"]="'unless-stopped'"
                ["Restart On Failure"]="'on-failure'"
                ["Always Restart"]="'always'"
                ["Never Restart"]="'no'"
            )
            PossibleOptions+=(
                "${DefaultValue}"
                "Restart Unless Stopped"
                "Restart On Failure"
                "Always Restart"
                "Never Restart"
            )
            ;;
        "${APPNAME}__TAG")
            ValueDescription='\n\n Tag is usually latest but can also be other values based on the image.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValue}"
            )
            ;;
        "${APPNAME}__VOLUME_"*)
            ValueDescription='\n\n If the directory selected does not exist we will attempt to create it.'
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValue}"
            )
            ;;
        *)
            ValueDescription=""
            OptionValue+=(
                ["${DefaultValue}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValue}"
            )
            ;;
    esac
    PossibleOptions+=("${PreviousValue}")

    if [[ -n ${OptionValue["${SystemValue}"]-} ]]; then
        ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
    fi

    while true; do
        # editorconfig-checker-disable
        local DescriptionHeading="
Application: ${ColorHeading}${AppName}\Zn
       File: ${ColorHeading}${VarFile}\Zn
   Variable: ${ColorHeading}${CleanVarName}\Zn
      Value: ${ColorHeading}${OptionValue["${CurrentValue}"]-}\Zn
"
        # editorconfig-checker-enable
        local SelectValueMenuText="${DescriptionHeading}\nWhat would you like set for ${CleanVarName}?${ValueDescription}"

        local -a ValidOptions=()
        local -a ValueOptions=()
        for Option in "${PossibleOptions[@]}"; do
            if [[ -n ${OptionValue["$Option"]-} ]]; then
                ValidOptions+=("${Option}")
                ValueOptions+=("${Option}" "${OptionValue["$Option"]}")
            fi
        done
        local ValidOptionsRegex
        {
            IFS='|'
            ValidOptionsRegex="${ValidOptions[*]}"
        }

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
            --inputmenu "${SelectValueMenuText}"
            $((LINES - 5)) $((COLUMNS - 5)) 0
            "${ValueOptions[@]}"
        )
        SelectValueDialogButtonPressed=0
        SelectedValue=$(dialog "${SelectValueDialog[@]}") || SelectValueDialogButtonPressed=$?

        case ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} in
            OK) # SELECT button
                if [[ ${SelectedValue} =~ ${ValidOptionsRegex} ]]; then
                    if [[ -n ${OptionValue["${SelectedValue}"]-} ]]; then
                        OptionValue["${CurrentValue}"]="${OptionValue["${SelectedValue}"]}"
                    else
                        error "Unset value '${SelectedValue}'"
                    fi
                else
                    error "Invalid option '${SelectedValue}'"
                fi
                ;;
            EXTRA) # EDIT button
                OptionValue["${CurrentValue}"]=$(grep -o -P "RENAMED (${ValidOptionsRegex}) \K.*" <<< "${SelectedValue}")
                ;;
            CANCEL | ESC) # DONE button
                local ValueValid
                if [[ ${OptionValue["${CurrentValue}"]} == *"$"* ]]; then
                    # Value contains a '$', assume it uses variable interpolation and allow it
                    ValueValid="true"
                else
                    local StrippedValue="${OptionValue["${CurrentValue}"]}"
                    # Strip comments from the value
                    #StrippedValue="$(sed -E "s/('([^']|'')*'|\"([^\"]|\"\")*\")|(#.*)//g" <<< "${StrippedValue}")"
                    #dialog --colors --title "${Title}" --msgbox "Original Value=${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn\nStripped Value=${ColorHighlight}${StrippedValue}\Zn" 0 0
                    # Unqauote the value
                    StrippedValue="$(sed -E "s|^(['\"])(.*)\1$|\2|g" <<< "${StrippedValue}")"

                    case "${VarName}" in
                        "${APPNAME}__ENABLED")
                            if [[ ${StrippedValue} == true ]] || [[ ${StrippedValue} == false ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${OptionValue["${CurrentValue}"]} is not true or false. Please try setting ${CleanVarName} again." 0 0
                            fi
                            ;;
                        "${APPNAME}__NETWORK_MODE")
                            case "${StrippedValue}" in
                                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid network mode. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__PORT_"*)
                            printf '%s' "${OptionValue["${CurrentValue}"]}"
                            if [[ ${StrippedValue} =~ ^[0-9]+$ ]] || [[ ${StrippedValue} -ge 0 ]] || [[ ${StrippedValue} -le 65535 ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid port. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                            fi
                            ;;
                        "${APPNAME}__RESTART")
                            case "${StrippedValue}" in
                                "no" | "always" | "on-failure" | "unless-stopped")
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --colors --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid restart value. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__VOLUME_"*)
                            if [[ ${StrippedValue} == "/" ]]; then
                                dialog --title "${Title}" --msgbox "${DescriptionHeading}\nCannot use / for ${CleanVarName}. Please select another folder." 0 0
                                ValueValid="false"
                            elif [[ ${StrippedValue} == ~* ]]; then
                                local CORRECTED_DIR="${DETECTED_HOMEDIR}${OptionValue["${CurrentValue}"]#*~}"
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nCannot use the ~ shortcut in ${CleanVarName}. Would you like to use ${CORRECTED_DIR} instead?" "${Title}"; then
                                    OptionValue["${CurrentValue}"]="${CORRECTED_DIR}"
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "Returning to the previous menu to confirm selection." 0 0
                                else
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\nCannot use the ~ shortcut in ${CleanVarName}. Please select another folder." 0 0
                                fi
                            elif [[ -d ${StrippedValue} ]]; then
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nWould you like to set permissions on ${OptionValue["${CurrentValue}"]} ?" "${Title}"; then
                                    run_script_dialog "Settings Permissions" "${StrippedValue}" "" \
                                        'set_permissions' "${StrippedValue}"
                                fi
                                ValueValid="true"
                            else
                                if run_script 'question_prompt' Y "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                                    {
                                        mkdir -p "${StrippedValue}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${StrippedValue}\""
                                        run_script 'set_permissions' "${StrippedValue}"
                                    } | dialog_pipe "Creating folder and settings permissions" "${OptionValue["${CurrentValue}"]}"
                                    dialog --colors --title "${Title}" --msgbox "${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn folder was created successfully." 0 0
                                    ValueValid="true"
                                else
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid path. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
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
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValue}"]}\Zn is not a valid ${CleanVarName}. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
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
                    run_script 'env_set_literal' "${VarName}" "${OptionValue["${CurrentValue}"]}"
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
