#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_value_prompt() {
    local VarName=${1-}
    local CleanVarName="${VarName}"

    if [[ ${CI-} == true ]]; then
        return
    fi

    local APPNAME appname AppName

    local AppDepreciatedTag="[*DEPRECIATED*]"
    local AppDisabledTag="(Disabled)"
    local AppUserDefinedTag="(User Defined)"
    local VarUserDefinedTag="(User Defined)"
    local VarDeletedTag="* DELETED *"

    local Title
    local VarFile DefaultVarFile
    local CleanVarName="${VarName}"
    local AppIsDisabled=''
    local AppIsDepreciated=''
    local AppIsUserDefined=''
    local VarIsUserDefined=''

    local VarType

    local APPNAME appname AppName
    APPNAME="$(run_script 'varname_to_appname' "${VarName}")"
    APPNAME="${APPNAME^^}"
    appname="${APPNAME,,}"
    AppName="$(run_script 'app_nicename' "${APPNAME}")"
    if [[ -n ${APPNAME} ]]; then
        Title="Edit Application Variable"
        if [[ ${VarName} == *":"* ]]; then
            VarType="APPENV"
            CleanVarName=${VarName#*:}
            VarName="${APPNAME}:${CleanVarName}"
            DefaultVarFile="$(run_script 'app_instance_file' "${appname}" ".app.env")"
        else
            VarType="APP"
            VarFile="${COMPOSE_ENV}"
            DefaultVarFile="$(run_script 'app_instance_file' "${appname}" ".global.env")"
        fi
        if run_script 'app_is_user_defined' "${appname}"; then
            AppIsUserDefined='Y'
            VarIsUserDefined='Y'
        else
            if run_script 'app_is_disabled' "${appname}"; then
                AppIsDisabled='Y'
            fi
            if run_script 'app_is_depreciated' "${appname}"; then
                AppIsDepreciated='Y'
            fi
            if ! run_script 'env_var_exists' "${CleanVarName}" "${DefaultVarFile}"; then
                VarIsUserDefined='Y'
            fi
        fi
    else
        Title="Edit Global Variable"
        VarType="GLOBAL"
        VarFile="${COMPOSE_ENV}"
        DefaultVarFile="${COMPOSE_ENV_DEFAULT_FILE}"
        if ! run_script 'env_var_exists' "${CleanVarName}" "${DefaultVarFile}"; then
            VarIsUserDefined='Y'
        fi
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
                    ValueDescription="\n\n This is used to set the application as enabled or disabled. If this variable is removed, the application will not be controlled by DockSTARTer. Must be ${DC[Highlight]}true${DC[NC]} or ${DC[Highlight]}false${DC[NC]}."
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
                        "Use Privoxy"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
                        ["Bridge Network"]="'bridge'"
                        ["Host Network"]="'host'"
                        ["No Network"]="'none'"
                        ["Use Gluetun"]="'service:gluetun'"
                        ["Use Privoxy"]="'service:privoxy'"
                    )
                    ;;
                "${APPNAME}__PORT_"*)
                    ValueDescription="\n\n Must be an unused port between ${DC[Highlight]}0${DC[NC]} and ${DC[Highlight]}65535${DC[NC]}."
                    PossibleOptions+=(
                        "${DefaultValueOption}"
                    )
                    OptionValue+=(
                        ["${DefaultValueOption}"]="$(run_script 'var_default_value' "${VarName}")"
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
    local AppNameLabel="   Application: "
    local AppNameHeading="${AppNameLabel}${DC[Heading]}${AppName}${DC[NC]}"
    if [[ ${AppIsUserDefined} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}${AppUserDefinedTag}${DC[NC]}"
    elif [[ ${AppIsDepreciated} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}${AppDepreciatedTag}${DC[NC]}"
    fi
    if [[ ${AppIsDisabled} == 'Y' ]]; then
        AppNameHeading="${AppNameHeading} ${DC[HeadingTag]}${AppDisabledTag}${DC[NC]}"
    fi
    local FilenameHeading="          File: ${DC[Heading]}${VarFile}${DC[NC]}"
    local VarNameHeading="      Variable: ${DC[Heading]}${CleanVarName}${DC[NC]}"
    if [[ ${VarIsUserDefined} == 'Y' ]]; then
        VarNameHeading="${VarNameHeading} ${DC[HeadingTag]}${VarUserDefinedTag}${DC[NC]}"
    fi
    local OriginalValueHeading="Original Value: "
    if [[ -n ${OptionValue["${OriginalValueOption}"]-} ]]; then
        OriginalValueHeading="${OriginalValueHeading}${DC[Heading]}${OptionValue["${OriginalValueOption}"]-}${DC[NC]}"
    else
        OriginalValueHeading="${OriginalValueHeading}${DC[Highlight]}${VarDeletedTag}${DC[NC]}"
    fi
    while true; do
        local CurrentValueHeading=" Current Value: "
        if [[ -n ${OptionValue["${CurrentValueOption}"]-} ]]; then
            CurrentValueHeading="${CurrentValueHeading}${DC[HeadingValue]}${OptionValue["${CurrentValueOption}"]-}${DC[NC]}"
        else
            CurrentValueHeading="${CurrentValueHeading}${DC[Highlight]}${VarDeletedTag}${DC[NC]}"
        fi
        local -a ValidOptions=()
        local -a ValueOptions=()
        for Option in "${PossibleOptions[@]}"; do
            if [[ -n ${OptionValue["$Option"]-} ]] || [[ ${Option} == "${CurrentValueOption}" ]] || [[ ${Option} == "${OriginalValueOption}" ]]; then
                ValidOptions+=("${Option}")
                ValueOptions+=("${Option}" "${OptionValue["$Option"]}")
            fi
        done
        ValidOptions+=("${DeleteOption}")
        ValueOptions+=("${DeleteOption}" "")
        local ValidOptionsRegex
        {
            IFS='|'
            ValidOptionsRegex="${ValidOptions[*]}"
        }
        local DescriptionHeading="${DC[NC]}"
        # editorconfig-checker-disable
        if [[ -n ${AppName-} ]]; then
            DescriptionHeading+="${AppNameHeading}${DC[NC]}\n"
            local AppDescription
            AppDescription="$(run_script 'app_description' "${AppName}")"
            local -i LabelWidth=${#AppNameLabel}
            local -i TextWidth=$((COLUMNS - DC["TextWidthAdjust"] - LabelWidth))
            local Indent
            Indent="$(printf "%${LabelWidth}s" "")"
            local -a AppDesciption
            readarray -t AppDesciption < <(fmt -w ${TextWidth} <<< "${AppDescription}")
            DescriptionHeading+="$(printf "${Indent}${DC[HeadingAppDescription]}%s${DC[NC]}\n" "${AppDesciption[@]-}")"
            DescriptionHeading+="\n\n"
        fi
        local DescriptionHeading+="
${FilenameHeading}
${VarNameHeading}

${OriginalValueHeading}
${CurrentValueHeading}
"
        # editorconfig-checker-enable
        local SelectValueMenuText="${DescriptionHeading}\nWhat would you like set for ${DC[Highlight]}${CleanVarName}${DC[NC]}?${ValueDescription}"
        local SelectValueDialogParams=(
            --stdout
            --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}"
            --colors
            --title "${DC["Title"]}${Title}"
        )
        local -i MenuTextLines
        MenuTextLines="$(dialog "${SelectValueDialogParams[@]}" --print-text-size "${SelectValueMenuText}" "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))" | cut -d ' ' -f 1)"
        local -i SelectValueDialogButtonPressed=0
        local SelectedValue
        local -a SelectValueDialog=(
            "${SelectValueDialogParams[@]}"
            --ok-label "Select"
            --extra-label "Edit"
            --cancel-label "Done"
            --inputmenu "${SelectValueMenuText}"
            "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
            "$((LINES - DC["TextHeightAdjust"] - MenuTextLines))"
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
                    # Value is empty, variable will be deleted
                    ValueValid="true"
                elif [[ ${OptionValue["${CurrentValueOption}"]} == *"$"* ]]; then
                    # Value contains a '$', assume it uses variable interpolation and allow it
                    ValueValid="true"
                else
                    local StrippedValue="${OptionValue["${CurrentValueOption}"]}"
                    # Strip comments from the value
                    #StrippedValue="$(sed -E "s/('([^']|'')*'|\"([^\"]|\"\")*\")|(#.*)//g" <<< "${StrippedValue}")"
                    #dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "Original Value=${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]}\nStripped Value=${DC[Highlight]}${StrippedValue}${DC[NC]}" "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                    # Unqauote the value
                    StrippedValue="$(sed -E "s|^(['\"])(.*)\1$|\2|g" <<< "${StrippedValue}")"

                    case "${VarName}" in
                        "${APPNAME}__ENABLED")
                            if [[ ${StrippedValue} == true ]] || [[ ${StrippedValue} == false ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not ${DC[Highlight]}true${DC[NC]} or ${DC[Highlight]}false${DC[NC]}. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                            fi
                            ;;
                        "${APPNAME}__NETWORK_MODE")
                            case "${StrippedValue}" in
                                "" | "bridge" | "host" | "none" | "service:"* | "container:"*)
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}"--colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid network mode. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__PORT_"*)
                            printf '%s' "${OptionValue["${CurrentValueOption}"]}"
                            if [[ ${StrippedValue} =~ ^[0-9]+$ ]] || [[ ${StrippedValue} -ge 0 ]] || [[ ${StrippedValue} -le 65535 ]]; then
                                ValueValid="true"
                            else
                                ValueValid="false"
                                dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid port. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                            fi
                            ;;
                        "${APPNAME}__RESTART")
                            case "${StrippedValue}" in
                                "no" | "always" | "on-failure" | "unless-stopped")
                                    ValueValid="true"
                                    ;;
                                *)
                                    ValueValid="false"
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid restart value. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                                    ;;
                            esac
                            ;;
                        "${APPNAME}__VOLUME_"*)
                            if [[ ${StrippedValue} == "/" ]]; then
                                dialog --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\nCannot use ${DC[Highlight]}/${DC[NC]} for ${DC[Highlight]}${CleanVarName}${DC[NC]}. Please select another folder." 0 0
                                ValueValid="false"
                            elif [[ ${StrippedValue} == *~* ]]; then
                                local CORRECTED_DIR="${OptionValue["${CurrentValueOption}"]//\~/"${DETECTED_HOMEDIR}"}"
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nCannot use the ${DC[Highlight]}~${DC[NC]} shortcut in ${DC[Highlight]}${CleanVarName}${DC[NC]}. Would you like to use ${DC[Highlight]}${CORRECTED_DIR}${DC[NC]} instead?" "${Title}"; then
                                    OptionValue["${CurrentValueOption}"]="${CORRECTED_DIR}"
                                    ValueValid="false"
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "Returning to the previous menu to confirm selection." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                                else
                                    ValueValid="false"
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\nCannot use the ${DC[Highlight]}~${DC[NC]} shortcut in ${DC[Highlight]}${CleanVarName}${DC[DC]}. Please select another folder." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                                fi
                            elif [[ -d ${StrippedValue} ]]; then
                                if run_script 'question_prompt' Y "${DescriptionHeading}\nWould you like to set permissions on ${OptionValue["${CurrentValueOption}"]} ?" "${Title}"; then
                                    run_script_dialog "Setting Permissions" "${DC[Heading]}${StrippedValue}${DC[NC]}" "${DIALOGTIMEOUT}" \
                                        'set_permissions' "${StrippedValue}"
                                fi
                                ValueValid="true"
                            else
                                if run_script 'question_prompt' Y "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid path. Would you like to attempt to create it?" "${Title}"; then
                                    {
                                        mkdir -p "${StrippedValue}" || fatal "Failed to make directory.\nFailing command: ${F[C]}mkdir -p \"${StrippedValue}\""
                                        run_script 'set_permissions' "${StrippedValue}"
                                    } | dialog_pipe "Creating folder and settings permissions" "${OptionValue["${CurrentValueOption}"]}" "${DIALOGTIMEOUT}"
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} folder was created successfully." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
                                    ValueValid="true"
                                else
                                    dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid path. Please try setting ${DC[Highlight]}${CleanVarName}${DC[NC]} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
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
                                dialog --begin "${DC[OffsetTop]}" "${DC[OffsetLeft]}" --colors --title "${DC["Title"]}${Title}" --msgbox "${DescriptionHeading}\n${DC[Highlight]}${OptionValue["${CurrentValueOption}"]}${DC[NC]} is not a valid ${CleanVarName}. Please try setting ${CleanVarName} again." "$((LINES - DC["WindowHeightAdjust"]))" "$((COLUMNS - DC["WindowWidthAdjust"]))"
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
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nDo you really want to delete ${DC[Highlight]}${CleanVarName}${DC[NC]}?\n" "Delete Variable" "" "Delete" "Back"; then
                            # Value is empty, delete the variable
                            {
                                run_script 'env_delete' "${VarName}"
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_migrate' "${APPNAME}"
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_sanitize'

                                    fi
                                else
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_sanitize'
                                    run_script 'env_update'
                                fi
                            } |& dialog_pipe "Deleting Variable" "${DescriptionHeading}" "${DIALOGTIMEOUT}"
                            return 0
                        fi
                    elif [[ ${OptionValue["${CurrentValueOption}"]-} == "${OptionValue["${OriginalValueOption}"]-}" ]]; then
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nThe value of ${DC[Highlight]}${CleanVarName}${DC[NC]} has not been changed, exit anyways?\n" "Save Variable" "" "Done" "Back"; then
                            # Value has not changed, confirm exiting
                            {
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_migrate' "${APPNAME}"
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_update'
                                    run_script 'env_sanitize'
                                fi
                            } |& dialog_pipe "Canceling Variable Edit" "${DescriptionHeading}" "${DIALOGTIMEOUT}"
                            return 0
                        fi
                    else
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\nWould you like to save ${DC[Highlight]}${CleanVarName}${DC[NC]}?\n" "Save Variable" "" "Save" "Back"; then
                            # Value is valid, save it and exit
                            {
                                run_script 'env_set_literal' "${VarName}" "${OptionValue["${CurrentValueOption}"]}"
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_migrate' "${APPNAME}"
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_update'
                                    run_script 'env_sanitize'
                                fi
                            } |& dialog_pipe "Saving Variable" "${DescriptionHeading}" "${DIALOGTIMEOUT}"
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
