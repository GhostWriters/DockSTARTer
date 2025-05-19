#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    # Dialog color codes to be used in the GUI menu
    # shellcheck disable=SC2168 # local is only valid in functions
    local \
        ColorHeading \
        ColorHeadingValue \
        ColorHighlight
    # shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
    {
        ColorHeading='\Zr'
        ColorHeadingValue='\Zb\Zr'
        ColorHighlight='\Z3\Zb'
    }
    # shellcheck disable=SC2168 # local is only valid in functions
    local \
        ColorLineHeading \
        ColorLineComment \
        ColorLineOther \
        ColorLineVar \
        ColorLineAddVariable
    # shellcheck disable=SC2034 # variable appears unused. Verify it or export it.
    {
        ColorLineHeading='\Zn'
        ColorLineComment='\Z0\Zb\Zr'
        ColorLineOther="${ColorLineComment}"
        ColorLineVar='\Z0\ZB\Zr'
        ColorLineAddVariable="${ColorLineVar}"
    }

    local VarName=${1-}
    local VarIsUserDefined=${2-}

    if [[ ${CI-} == true ]]; then
        return
    fi

    local Title="Edit Variable"

    local DialogTimeout=2
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
        if [[ ${VarName} == *":"* ]]; then
            CleanVarName=${VarName#*:}
            VarFile="$(run_script 'app_env_file' "${appname}")"
            DefaultVarFile="$(run_script 'app_instance_file' "${appname}" ".app.env")"
        else
            DefaultVarFile="$(run_script 'app_instance_file' "${appname}" ".global.env")"
        fi
    fi
    local AppIsUserDefined
    local VarIsUserDefined
    if run_script 'app_is_builtin' "${appname}"; then
        AppIsUserDefined=''
        if run_script 'env_var_exists' "${CleanVarName}" "${DefaultVarFile}"; then
            VarIsUserDefined=''
        else
            VarIsUserDefined='Y'
        fi
    else
        AppIsUserDefined='Y'
        VarIsUserDefined='Y'
    fi

    local DeleteOption="=== DELETE ==="
    local CurrentValueOption="Current Value"
    local DefaultValueOption="Default Value"
    local SystemValueOption="System Value"
    local OriginalValueOption="Original Value"

    local ValueDescription=""
    local -A OptionValue=()
    OptionValue["${OriginalValueOption}"]=$(run_script 'env_get_literal' "${VarName}")
    OptionValue["${CurrentValueOption}"]="${OptionValue["${OriginalValueOption}"]}"

    local -a PossibleOptions=("${CurrentValueOption}")
    case "${VarName}" in
        DOCKER_GID)
            ValueDescription="\n\n This should be the Docker group ID. If you are unsure, select ${ColorHighlight}${SystemValueOption}\Zn."
            OptionValue+=(
                ["${SystemValueOption}"]="'$(cut -d: -f3 < <(getent group docker))'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        DOCKER_HOSTNAME)
            ValueDescription="\n\n This should be your system hostname. If you are unsure, select ${ColorHighlight}${SystemValueOption}\Zn."
            OptionValue+=(
                ["${SystemValueOption}"]="'${HOSTNAME}'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        DOCKER_VOLUME_CONFIG)
            OptionValue+=(
                ["Home Folder"]="'${DETECTED_HOMEDIR}/.config/appdata'"
            )
            PossibleOptions+=(
                "Home Folder"
            )
            ;;
        DOCKER_VOLUME_STORAGE)
            OptionValue+=(
                ["Home Folder"]="'${DETECTED_HOMEDIR}/storage'"
                ["Mount Folder"]="'/mnt/storage'"
            )
            PossibleOptions+=(
                "Home Folder"
                "Mount Folder"
            )
            ;;
        GLOBAL_LAN_NETWORK)
            ValueDescription="\n\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more."
            OptionValue+=(
                ["${SystemValueOption}"]="'$(run_script 'detect_lan_network')'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        PGID)
            ValueDescription="\n\n This should be your user group ID. If you are unsure, select ${ColorHighlight}${SystemValueOption}\Zn."
            OptionValue+=(
                ["${SystemValueOption}"]="'${DETECTED_PGID}'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        PUID)
            ValueDescription="\n\n This should be your user account ID. If you are unsure, select ${ColorHighlight}${SystemValueOption}\Zn."
            OptionValue+=(
                ["${SystemValueOption}"]="'${DETECTED_PUID}'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        TZ)
            ValueDescription="\n\n If this is not the correct timezone please exit and set your system timezone."
            OptionValue+=(
                ["${SystemValueOption}"]="'$(cat /etc/timezone)'"
            )
            PossibleOptions+=(
                "${SystemValueOption}"
            )
            ;;
        "${APPNAME}__ENABLED")
            ValueDescription="\n\n Must be true or false."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
            )
            ;;
        "${APPNAME}__NETWORK_MODE")
            ValueDescription="\n\n Network Mode is usually left blank but can also be ${ColorHighlight}bridge\Zn, ${ColorHighlight}host\Zn, ${ColorHighlight}none\Zn, ${ColorHighlight}service:<appname>\Zn, or ${ColorHighlight}container:<appname>\Zn."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
                ["Bridge Network"]="'bridge'"
                ["Host Network"]="'host'"
                ["No Network"]="'none'"
                ["Use Gluetun"]="'service:gluetun'"
                ["Use Privoxy"]="'service:privoxy'"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
                "Bridge Network"
                "Host Network"
                "No Network"
                "Use Gluetun"
                "Use Privoxy"
            )
            ;;
        "${APPNAME}__PORT_"*)
            ValueDescription="\n\n Must be an unused port between ${ColorHighlight}0\Zn and ${ColorHighlight}65535\Zn."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
            )
            ;;
        "${APPNAME}__RESTART")
            ValueDescription="\n\n Restart is usually ${ColorHighlight}unless-stopped\Zn but can also be ${ColorHighlight}no\Zn, ${ColorHighlight}always\Zn, or ${ColorHighlight}on-failure\Zn."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
                ["Restart Unless Stopped"]="'unless-stopped'"
                ["Never Restart"]="'no'"
                ["Always Restart"]="'always'"
                ["Restart On Failure"]="'on-failure'"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
                "Restart Unless Stopped"
                "Never Restart"
                "Always Restart"
                "Restart On Failure"
            )
            ;;
        "${APPNAME}__TAG")
            ValueDescription="\n\n Tag is usually latest but can also be other values based on the image."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
            )
            ;;
        "${APPNAME}__VOLUME_"*)
            ValueDescription="\n\n If the directory selected does not exist we will attempt to create it."
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
            )
            ;;
        *)
            ValueDescription=""
            OptionValue+=(
                ["${DefaultValueOption}"]="$(run_script 'env_get_literal' "${CleanVarName}" "${DefaultVarFile}")"
            )
            PossibleOptions+=(
                "${DefaultValueOption}"
            )
            ;;
    esac
    PossibleOptions+=("${OriginalValueOption}")

    if [[ -n ${OptionValue["${SystemValueOption}"]-} ]]; then
        ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
    fi
    local AppNameHeading="   Application: ${ColorHeading}${AppName}\Zn"
    if [[ ${AppIsUserDefined} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${ColorHighlight}*User Defined*\Zn"
    fi
    local FilenameHeading="          File: ${ColorHeading}${VarFile}\Zn"
    local VarNameHeading="      Variable: ${ColorHeading}${CleanVarName}\Zn"
    if [[ ${VarIsUserDefined} == 'Y' ]]; then
        VarNameHeading="${VarNameHeading} ${ColorHighlight}*User Defined*\Zn"
    fi
    local OriginalValueHeading="Original Value: "
    if [[ -n ${OptionValue["${OriginalValueOption}"]-} ]]; then
        OriginalValueHeading="${OriginalValueHeading}${ColorHeading}${OptionValue["${OriginalValueOption}"]-}\Zn"
    else
        OriginalValueHeading="${OriginalValueHeading}${ColorHighlight}* DELETED *\Zn"
    fi
    while true; do
        local CurrentValueHeading=" Current Value: "
        if [[ -n ${OptionValue["${CurrentValueOption}"]-} ]]; then
            CurrentValueHeading="${CurrentValueHeading}${ColorHeadingValue}${OptionValue["${CurrentValueOption}"]-}\Zn"
        else
            CurrentValueHeading="${CurrentValueHeading}${ColorHighlight}* DELETED *\Zn"
        fi
        local -a ValidOptions=()
        local -a ValueOptions=()
        for Option in "${PossibleOptions[@]}"; do
            if [[ -n ${OptionValue["$Option"]-} ]] || [[ ${Option} == "${CurrentValueOption}" ]] || [[ ${Option} == "${OriginalValueOption}" ]]; then
                ValidOptions+=("${Option}")
                ValueOptions+=("${Option}" "${OptionValue["$Option"]}")
            fi
        done
        if [[ ${VarIsUserDefined} == 'Y' ]]; then
            ValidOptions+=("${DeleteOption}")
            ValueOptions+=("${DeleteOption}" "")
        fi
        local ValidOptionsRegex
        {
            IFS='|'
            ValidOptionsRegex="${ValidOptions[*]}"
        }
        local DescriptionHeading=""
        # editorconfig-checker-disable
        if [[ -n ${AppName-} ]]; then
            DescriptionHeading="${DescriptionHeading}\n${AppNameHeading}\Zn"
        fi
        local DescriptionHeading="${DescriptionHeading}
${FilenameHeading}
${VarNameHeading}

${OriginalValueHeading}
${CurrentValueHeading}
"
        # editorconfig-checker-enable
        local SelectValueMenuText="${DescriptionHeading}\nWhat would you like set for ${ColorHighlight}${CleanVarName}\Zn?${ValueDescription}"

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
                if [[ ${SelectedValue} == "${DeleteOption}" ]]; then
                    OptionValue["${CurrentValueOption}"]=""
                elif [[ ${SelectedValue} =~ ${ValidOptionsRegex} ]]; then
                    if [[ -n ${OptionValue["${SelectedValue}"]-} ]]; then
                        OptionValue["${CurrentValueOption}"]="${OptionValue["${SelectedValue}"]}"
                    else
                        error "Unset value '${SelectedValue}'"
                    fi
                else
                    error "Invalid option '${SelectedValue}'"
                fi
                ;;
            EXTRA) # EDIT button
                OptionValue["${CurrentValueOption}"]=$(grep -o -P "RENAMED (${ValidOptionsRegex}) \K.*" <<< "${SelectedValue}")
                ;;
            CANCEL | ESC) # DONE button
                local ValueValid
                if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
                    if [[ ${VarIsUserDefined} == 'Y' ]]; then
                        ValueValid="true"
                    else
                        ValueValid="false"
                        dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\nYou are not allowed to delete built-in variables.\nPlease try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                    fi
                elif [[ ${OptionValue["${CurrentValueOption}"]} == *"$"* ]]; then
                    # Value contains a '$', assume it uses variable interpolation and allow it
                    ValueValid="true"
                else
                    local StrippedValue="${OptionValue["${CurrentValueOption}"]}"
                    # Strip comments from the value
                    #StrippedValue="$(sed -E "s/('([^']|'')*'|\"([^\"]|\"\")*\")|(#.*)//g" <<< "${StrippedValue}")"
                    #dialog --colors --title "${Title}" --msgbox "Original Value=${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn\nStripped Value=${ColorHighlight}${StrippedValue}\Zn" 0 0
                    # Unqauote the value
                    StrippedValue="$(sed -E "s|^(['\"])(.*)\1$|\2|g" <<< "${StrippedValue}")"

                    case "${VarName}" in
                        "${APPNAME}__ENABLED")
                            if [[ ${StrippedValue} == true ]] || [[ ${StrippedValue} == false ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${OptionValue["${CurrentValueOption}"]} is not true or false. Please try setting ${CleanVarName} again." 0 0
                            fi
                            ;;
                        "${APPNAME}__NETWORK_MODE")
                            case "${StrippedValue}" in
                                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid network mode. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__PORT_"*)
                            printf '%s' "${OptionValue["${CurrentValueOption}"]}"
                            if [[ ${StrippedValue} =~ ^[0-9]+$ ]] || [[ ${StrippedValue} -ge 0 ]] || [[ ${StrippedValue} -le 65535 ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid port. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                            fi
                            ;;
                        "${APPNAME}__RESTART")
                            case "${StrippedValue}" in
                                "no" | "always" | "on-failure" | "unless-stopped")
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --colors --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid restart value. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__VOLUME_"*)
                            if [[ ${StrippedValue} == "/" ]]; then
                                dialog --title "${Title}" --msgbox "${DescriptionHeading}\nCannot use / for ${CleanVarName}. Please select another folder." 0 0
                                ValueValid="false"
                            elif [[ ${StrippedValue} == ~* ]]; then
                                local CORRECTED_DIR="${DETECTED_HOMEDIR}${OptionValue["${CurrentValueOption}"]#*~}"
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nCannot use the ~ shortcut in ${CleanVarName}. Would you like to use ${CORRECTED_DIR} instead?" "${Title}"; then
                                    OptionValue["${CurrentValueOption}"]="${CORRECTED_DIR}"
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "Returning to the previous menu to confirm selection." 0 0
                                else
                                    ValueValid="false"
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\nCannot use the ~ shortcut in ${CleanVarName}. Please select another folder." 0 0
                                fi
                            elif [[ -d ${StrippedValue} ]]; then
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nWould you like to set permissions on ${OptionValue["${CurrentValueOption}"]} ?" "${Title}"; then
                                    run_script_dialog "Setting Permissions" "${ColorHeading}${StrippedValue}\Zn" "${DialogTimeout}" \
                                        'set_permissions' "${StrippedValue}"
                                fi
                                ValueValid="true"
                            else
                                if run_script 'question_prompt' Y "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                                    {
                                        mkdir -p "${StrippedValue}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${StrippedValue}\""
                                        run_script 'set_permissions' "${StrippedValue}"
                                    } | dialog_pipe "Creating folder and settings permissions" "${OptionValue["${CurrentValueOption}"]}" "${DialogTimeout}"
                                    dialog --colors --title "${Title}" --msgbox "${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn folder was created successfully." 0 0
                                    ValueValid="true"
                                else
                                    dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid path. Please try setting ${ColorHighlight}${CleanVarName}\Zn again." 0 0
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
                                dialog --colors --title "${Title}" --msgbox "${DescriptionHeading}\n${ColorHighlight}${OptionValue["${CurrentValueOption}"]}\Zn is not a valid ${CleanVarName}. Please try setting ${CleanVarName} again." 0 0
                                ValueValid="false"
                            fi
                            ;;
                        *)
                            ValueValid="true"
                            ;;
                    esac
                fi
                if ${ValueValid}; then
                    if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nDo you really want to delete ${ColorHighlight}${CleanVarName}\Zn?\n" "Delete Variable" "" "Delete" "Back"; then
                            # Value is empty, delete the variable
                            run_script_dialog "Deleting Variable" "${DescriptionHeading}" "${DialogTimeout}" \
                                'env_delete' "${VarName}"
                            return 0
                        fi
                    elif [[ ${OptionValue["${CurrentValueOption}"]-} == "${OptionValue["${OriginalValueOption}"]-}" ]]; then
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nThe value of ${ColorHighlight}${CleanVarName}\Zn has not been changed, exit anyways?\n" "Save Variable" "" "Done" "Back"; then
                            # Value has not changed, confirm exiting
                            return 0
                        fi
                    else
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nWould you like to save ${ColorHighlight}${CleanVarName}\Zn?\n" "Save Variable" "" "Save" "Back"; then
                            # Value is valid, save it and exit
                            run_script_dialog "Saving Variable" "${DescriptionHeading}" "${DialogTimeout}" \
                                'env_set_literal' "${VarName}" "${OptionValue["${CurrentValueOption}"]}"
                            return 0
                        fi
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

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
