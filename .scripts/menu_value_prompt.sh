#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local VarName=${1-}
    local CleanVarName="${VarName}"

    if [[ ${CI-} == true ]]; then
        return
    fi

    local APPNAME AppName

    local VarDeletedTag="${DC[Highlight]}[*DELETED*]"

    local Title
    local CleanVarName="${VarName}"

    local VarType

    local APPNAME
    APPNAME="$(run_script 'varname_to_appname' "${VarName}")"
    APPNAME="${APPNAME^^}"
    if [[ -n ${APPNAME} ]]; then
        Title="Edit Application Variable"
        if [[ ${VarName} == *":"* ]]; then
            VarType="APPENV"
            CleanVarName=${VarName#*:}
            VarName="${APPNAME}:${CleanVarName}"
        else
            VarType="APP"
        fi
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
    else
        Title="Edit Global Variable"
        VarType="GLOBAL"
    fi

    local CurrentValueOption="Current Value"
    local DefaultValueOption="Default Value"
    local SystemValueOption="System Value"
    local OriginalValueOption="Original Value"

    local ValueDescription=""
    local -A OptionHelpLine=()
    local -A OptionValue=()
    OptionValue["${OriginalValueOption}"]=$(run_script 'env_get_literal' "${VarName}")
    OptionHelpLine["${OriginalValueOption}"]="This is the original value before before entering the editor."
    OptionValue["${CurrentValueOption}"]="${OptionValue["${OriginalValueOption}"]}"
    OptionHelpLine["${CurrentValueOption}"]="This is the value that will be saved when you select Done."
    OptionHelpLine["${DefaultValueOption}"]="This is the recommended default value."
    OptionHelpLine["${SystemValueOption}"]="This is the recommended system detected value."
    local DeleteHelpLine="This will set the variable to be deleted when you select Done."

    local -a PossibleOptions=("${CurrentValueOption}")
    case "${VarType}" in
        GLOBAL)
            case "${VarName}" in
                DOCKER_GID)
                    ValueDescription="\n\n This should be the Docker group ID. If you are unsure, select ${DC[Highlight]}${SystemValueOption}${DC[NC]}."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                DOCKER_HOSTNAME)
                    ValueDescription="\n\n This should be your system hostname. If you are unsure, select ${DC[Highlight]}${SystemValueOption}${DC[NC]}."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                DOCKER_VOLUME_CONFIG)
                    PossibleOptions+=(
                        "Home Folder"
                    )
                    OptionValue+=(
                        ["Home Folder"]="'${DETECTED_HOMEDIR}/.config/appdata'"
                    )
                    ;;
                DOCKER_VOLUME_STORAGE)
                    PossibleOptions+=(
                        "Home Folder"
                        "Mount Folder"
                    )
                    OptionValue+=(
                        ["Home Folder"]="'${DETECTED_HOMEDIR}/storage'"
                        ["Mount Folder"]="'/mnt/storage'"
                    )
                    ;;
                GLOBAL_LAN_NETWORK)
                    ValueDescription="\n\n This is used to define your home LAN network, do NOT confuse this with the IP address of your router or your server, the value for this key defines your network NOT a single host. Please Google CIDR Notation to learn more."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                PGID)
                    ValueDescription="\n\n This should be your user group ID. If you are unsure, select ${DC[Highlight]}${SystemValueOption}${DC[NC]}."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                PUID)
                    ValueDescription="\n\n This should be your user account ID. If you are unsure, select ${DC[Highlight]}${SystemValueOption}${DC[NC]}."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                TZ)
                    ValueDescription="\n\n If this is not the correct timezone please exit and set your system timezone."
                    PossibleOptions+=(
                        "${SystemValueOption}"
                    )
                    OptionValue+=(
                        ["${SystemValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                *)
                    ValueDescription=""
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
            esac
            ;;
        APP)
            case "${VarName}" in
                "${APPNAME}__ENABLED")
                    ValueDescription="\n\n This is used to set the application as enabled or disabled. If this variable is removed, the application will not be controlled by ${APPLICATION_NAME}. Must be ${DC[Highlight]}true${DC[NC]} or ${DC[Highlight]}false${DC[NC]}."
                    PossibleOptions+=(
                        "Enabled"
                        "Disabled"
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["Enabled"]="'true'"
                        ["Disabled"]="'false'"
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                "${APPNAME}__NETWORK_MODE")
                    ValueDescription="\n\n Network Mode is usually left blank but can also be ${DC[Highlight]}bridge${DC[NC]}, ${DC[Highlight]}host${DC[NC]}, ${DC[Highlight]}none${DC[NC]}, ${DC[Highlight]}service:<appname>${DC[NC]}, or ${DC[Highlight]}container:<appname>${DC[NC]}."
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                        "Bridge Network"
                        "Host Network"
                        "No Network"
                        "Use Gluetun"
                        "Use PrivoxyVPN"
                    )
                    OptionHelpLine+=(
                        ["Bridge Network"]="Connects ${DC[Highlight]}${AppName}${DC[NC]} to the internal Docker bridge network. Same as leaving the value empty."
                        ["Host Network"]="Connects ${DC[Highlight]}${AppName}${DC[NC]} to the host OS's network."
                        ["No Network"]="Leaves ${DC[Highlight]}${AppName}${DC[NC]} without a network connection."
                        ["Use Gluetun"]="Connects ${DC[Highlight]}${AppName}${DC[NC]} to the VPN running in the ${DC[Highlight]}Gluetun${DC[NC]} container if running."
                        ["Use PrivoxyVPN"]="Connects ${DC[Highlight]}${AppName}${DC[NC]} to the VPN running in the ${DC[Highlight]}PrivoxyVPN${DC[NC]} container if running."
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                        ["Bridge Network"]="'bridge'"
                        ["Host Network"]="'host'"
                        ["No Network"]="'none'"
                        ["Use Gluetun"]="'service:gluetun'"
                        ["Use PrivoxyVPN"]="'service:privoxyvpn'"
                    )
                    ;;
                "${APPNAME}__RESTART")
                    ValueDescription="\n\n Restart is usually ${DC[Highlight]}unless-stopped${DC[NC]} but can also be ${DC[Highlight]}no${DC[NC]}, ${DC[Highlight]}always${DC[NC]}, or ${DC[Highlight]}on-failure${DC[NC]}."
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                        "Restart Unless Stopped"
                        "Never Restart"
                        "Always Restart"
                        "Restart On Failure"
                    )
                    OptionHelpLine+=(
                        ["Restart Unless Stopped"]="This will cause the application to restart unless the user manually stopped it."
                        ["Never Restart"]="This will cause the application to never restart."
                        ["Always Restart"]="This will cause the application to always restart"
                        ["Restart On Failure"]="This will cause the application to restart if it stops due to a failure."
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                        ["Restart Unless Stopped"]="'unless-stopped'"
                        ["Never Restart"]="'no'"
                        ["Always Restart"]="'always'"
                        ["Restart On Failure"]="'on-failure'"
                    )
                    ;;
                "${APPNAME}__TAG")
                    ValueDescription="\n\n Tag is usually latest but can also be other values based on the image."
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                "${APPNAME}__VOLUME_"*)
                    ValueDescription="\n\n If the directory selected does not exist we will attempt to create it."
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
                *)
                    if [[ ${VarName} =~ ^${APPNAME}__PORT_[0-9]+$ ]]; then
                        ValueDescription="\n\n Must be an unused port between ${DC[Highlight]}0${DC[NC]} and ${DC[Highlight]}65535${DC[NC]}."
                        PossibleOptions+=(
                            "${DefaultValueOption}"
                        )
                        OptionValue+=(
                            ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                        )
                    else
                        ValueDescription=""
                        PossibleOptions+=(
                            "${DefaultValueOption}"
                        )
                        OptionValue+=(
                            ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                        )
                    fi
                    ;;
            esac
            ;;
        APPENV)
            case "${VarName}" in
                *)
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                    )
                    ;;
            esac
            ;;
    esac
    PossibleOptions+=("${OriginalValueOption}")

    if [[ -n ${OptionValue["${SystemValueOption}"]-} ]]; then
        ValueDescription="\n\n System detected values are recommended.${ValueDescription}"
    fi

    while true; do
        local -a ValidOptions=()
        local -a ValueOptions=()
        local OptionsLength=0
        for Option in "${PossibleOptions[@]}"; do
            if [[ -n ${OptionValue["$Option"]-} ]] || [[ ${Option} == "${CurrentValueOption}" ]] || [[ ${Option} == "${OriginalValueOption}" ]]; then
                if [[ ${#Option} -gt OptionsLength ]]; then
                    OptionsLength=${#Option}
                fi
                ValidOptions+=("${Option}")
                ValueOptions+=("${Option}" "${OptionValue["$Option"]}" "${OptionHelpLine["$Option"]-}")
            fi
        done
        local DeleteOption=" DELETE "
        local Bar
        Bar=$(printf "%$(((OptionsLength - ${#DeleteOption}) / 2))s" '' | tr ' ' '=')
        DeleteOption=" ${Bar}${DeleteOption}${Bar}"
        ValidOptions+=("${DeleteOption}")
        ValueOptions+=("${DeleteOption}" "" "${DeleteHelpLine-}")

        local ValidOptionsRegex
        {
            IFS='|'
            ValidOptionsRegex="${ValidOptions[*]}"
        }

        local DialogHeading
        local CurrentValueHeading="${OptionValue["${CurrentValueOption}"]:-${VarDeletedTag}}"
        DialogHeading="$(run_script 'menu_heading' "${APPNAME}" "${VarName}" "${OptionValue["${OriginalValueOption}"]-}" "${CurrentValueHeading}")"
        local SelectValueMenuText="${DialogHeading}\n\nWhat would you like set for ${DC[Highlight]}${CleanVarName}${DC[NC]}?${ValueDescription}"
        local SelectValueDialogParams=(
            --output-fd 1
            --title "${DC["Title"]}${Title}"
            --item-help
        )
        local -i MenuTextLines
        MenuTextLines="$(_dialog_ "${SelectValueDialogParams[@]}" --print-text-size "${SelectValueMenuText}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" | cut -d ' ' -f 1)"
        local -i SelectValueDialogButtonPressed=0
        local SelectedValue
        local -a SelectValueDialog=(
            "${SelectValueDialogParams[@]}"
            --ok-label "Select"
            --extra-label "Edit"
            --cancel-label "Done"
            --inputmenu "${SelectValueMenuText}"
            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
            "$((LINES - DC["TextRowsAdjust"] - MenuTextLines))"
            "${ValueOptions[@]}"
        )
        SelectValueDialogButtonPressed=0
        SelectedValue=$(_dialog_ "${SelectValueDialog[@]}") || SelectValueDialogButtonPressed=$?

        case ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} in
            OK) # SELECT button
                if [[ ${SelectedValue} == "${DeleteOption}" ]]; then
                    OptionValue["${CurrentValueOption}"]=""
                elif [[ ${SelectedValue} =~ ${ValidOptionsRegex} ]]; then
                    if [[ -n ${OptionValue["${SelectedValue}"]-} ]]; then
                        OptionValue["${CurrentValueOption}"]="${OptionValue["${SelectedValue}"]}"
                    else
                        error "Unset value '${F[C]}${SelectedValue}${NC}'"
                    fi
                else
                    error "Invalid option '${F[C]}${SelectedValue}${NC}'"
                fi
                ;;
            EXTRA) # EDIT button
                OptionValue["${CurrentValueOption}"]=$(grep -o -P "^RENAMED (${ValidOptionsRegex}) \K.*" <<< "${SelectedValue}")
                ;;
            CANCEL | ESC) # DONE button
                local ValueValid
                if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
                    # Value is empty, variable will be deleted
                    ValueValid="true"
                elif [[ ${OptionValue["${CurrentValueOption}"]} == *"$"* ]]; then
                    # Value contains a '$', assume it uses variable interpolation and allow it
                    ValueValid="true"
                else
                    local StrippedValue="${OptionValue["${CurrentValueOption}"]}"
                    # Unqauote the value
                    StrippedValue="$(sed -E "s|^(['\"])(.*)\1$|\2|g" <<< "${StrippedValue}")"

                    case "${VarName}" in
                        "${APPNAME}__ENABLED")
                            case "${StrippedValue^^}" in
                                ON | TRUE | YES | OFF | FALSE | NO)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog_error "${Title}" "${DialogHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not ${DC[Highlight]}true${DC[NC]}/${DC[Highlight]}on${DC[NC]}/${DC[Highlight]}yes${DC[NC]} or ${DC[Highlight]}false${DC[NC]}/${DC[Highlight]}off${DC[NC]}/${DC[Highlight]}no${DC[NC]}. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__NETWORK_MODE")
                            case "${StrippedValue}" in
                                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog_error "${Title}" "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid network mode. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__RESTART")
                            case "${StrippedValue}" in
                                "no" | "always" | "on-failure" | "unless-stopped")
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog_error "${Title}" "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid restart value. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__VOLUME_"*)
                            if [[ ${StrippedValue} == "/" ]]; then
                                dialog_error "${Title}" "${DialogHeading}\n\nCannot use ${DC[Highlight]}/${DC[NC]} for ${DC[Highlight]}${CleanVarName}${DC[NC]}. Please select another folder."
                                ValueValid="false"
                            elif [[ ${StrippedValue} == *~* ]]; then
                                local CORRECTED_DIR="${OptionValue["${CurrentValueOption}"]//\~/"${DETECTED_HOMEDIR}"}"
                                if run_script 'question_prompt' Y "${DialogHeading}\n\nCannot use the ${DC[Highlight]}~${DC[NC]} shortcut in ${DC[Highlight]}${CleanVarName}${DC[NC]}. Would you like to use ${DC[Highlight]}${CORRECTED_DIR}${DC[NC]} instead?" "${Title}"; then
                                    OptionValue["${CurrentValueOption}"]="${CORRECTED_DIR}"
                                    ValueValid="false"
                                    dialog_success "${Title}" "Returning to the previous menu to confirm selection."
                                else
                                    ValueValid="false"
                                    dialog_error "${Title}" "${DialogHeading}\n\nCannot use the ${DC[Highlight]}~${DC[NC]} shortcut in ${DC[Highlight]}${CleanVarName}${DC[DC]}. Please select another folder."
                                fi
                            elif [[ -d ${StrippedValue} ]]; then
                                if run_script 'question_prompt' Y "${DialogHeading}\n\nWould you like to set permissions on ${OptionValue["${CurrentValueOption}"]} ?" "${Title}"; then
                                    run_script_dialog "Setting Permissions" "${DC[Heading]}${StrippedValue}${DC[NC]}" "${DIALOGTIMEOUT}" \
                                        'set_permissions' "${StrippedValue}"
                                fi
                                ValueValid="true"
                            else
                                if run_script 'question_prompt' Y "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                                    {
                                        mkdir -p "${StrippedValue}" || fatal "Failed to make directory.\nFailing command: ${C["FailingCommand"]}mkdir -p \"${StrippedValue}\""
                                        run_script 'set_permissions' "${StrippedValue}"
                                    } |& dialog_pipe "Creating folder and settings permissions" "${OptionValue["${CurrentValueOption}"]}" "${DIALOGTIMEOUT}"
                                    dialog_error "${DC["TitleSuccess"]}${Title}" --msgbox "${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} folder was created successfully." "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                                    ValueValid="true"
                                else
                                    dialog_error "${Title}" "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid path. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                    ValueValid="false"
                                fi
                            fi
                            ;;
                        P[GU]ID)
                            if [[ ${StrippedValue} =~ ^[0-9]+$ ]]; then
                                if [[ ${StrippedValue} -eq 0 ]]; then
                                    if run_script 'question_prompt' Y "${DialogHeading}\n\nRunning as ${DC[Highlight]}root${DC[NC]} is not recommended. Would you like to select a different ID?" "${Title}" ""; then
                                        ValueValid="false"
                                    else
                                        ValueValid="true"
                                    fi
                                else
                                    ValueValid="true"
                                fi
                            else
                                dialog_error "${Title}" "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid ${CleanVarName}. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                ValueValid="false"
                            fi
                            ;;
                        *)
                            if [[ ${VarName} =~ ^${APPNAME}__PORT_[0-9]+$ ]]; then
                                if [[ ${StrippedValue} =~ ^[0-9]+$ ]] && [[ ${StrippedValue} -ge 0 ]] && [[ ${StrippedValue} -le 65535 ]]; then
                                    ValueValid="true"
                                else
                                    ValueValid="false"
                                    dialog_error "${Title}" "${DialogHeading}\n\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid port. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again."
                                fi
                            else
                                ValueValid="true"
                            fi
                            ;;
                    esac
                fi
                if ${ValueValid}; then
                    if [[ -z ${OptionValue["${CurrentValueOption}"]-} ]]; then
                        if run_script 'question_prompt' N "${DialogHeading}\n\nDo you really want to delete ${DC[Highlight]}${CleanVarName}${DC[NC]}?\n" "Delete Variable" "" "Delete" "Back"; then
                            # Value is empty, delete the variable
                            coproc {
                                dialog_pipe "${DC["TitleSuccess"]}Deleting Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
                            }
                            local -i DialogBox_PID=${COPROC_PID}
                            local -i DialogBox_FD="${COPROC[1]}"
                            {
                                run_script 'env_delete' "${VarName}"
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_backup'
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_update'
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'env_backup'
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_sanitize'
                                    run_script 'env_update'
                                fi
                            } >&${DialogBox_FD} 2>&1
                            exec {DialogBox_FD}<&-
                            wait ${DialogBox_PID}
                            return 0
                        fi
                    elif [[ ${OptionValue["${CurrentValueOption}"]-} == "${OptionValue["${OriginalValueOption}"]-}" ]]; then
                        if run_script 'question_prompt' N "${DialogHeading}\n\nThe value of ${DC[Highlight]}${CleanVarName}${DC[NC]} has not been changed, exit anyways?\n" "Save Variable" "" "Done" "Back"; then
                            # Value has not changed, confirm exiting
                            coproc {
                                dialog_pipe "${DC["TitleSuccess"]}Canceling Variable Edit" "${DialogHeading}" "${DIALOGTIMEOUT}"
                            }
                            local -i DialogBox_PID=${COPROC_PID}
                            local -i DialogBox_FD="${COPROC[1]}"
                            {
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_backup'
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_update'
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'env_backup'
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_update'
                                    run_script 'env_sanitize'
                                fi
                            } >&${DialogBox_FD} 2>&1
                            exec {DialogBox_FD}<&-
                            wait ${DialogBox_PID}
                            return 0
                        fi
                    else
                        if run_script 'question_prompt' N "${DialogHeading}\n\nWould you like to save ${DC[Highlight]}${CleanVarName}${DC[NC]}?\n" "Save Variable" "" "Save" "Back"; then
                            # Value is valid, save it and exit
                            coproc {
                                dialog_pipe "${DC["TitleSuccess"]}Saving Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
                            }
                            local -i DialogBox_PID=${COPROC_PID}
                            local -i DialogBox_FD="${COPROC[1]}"
                            {
                                run_script 'env_set_literal' "${VarName}" "${OptionValue["${CurrentValueOption}"]}"
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_backup'
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_update'
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_update'
                                    run_script 'env_sanitize'
                                fi
                            } >&${DialogBox_FD} 2>&1
                            exec {DialogBox_FD}<&-
                            wait ${DialogBox_PID}
                            return 0
                        fi
                    fi
                fi
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} ]]; then
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[SelectValueDialogButtonPressed]}' pressed in menu_value_prompt."
                else
                    fatal "Unexpected dialog button value' ${SelectValueDialogButtonPressed}' pressed in menu_value_prompt."
                fi
                ;;
        esac
    done
}

test_menu_value_prompt() {
    # run_script 'menu_value_prompt'
    warn "CI does not test menu_value_prompt."
}
