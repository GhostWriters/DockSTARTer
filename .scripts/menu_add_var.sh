#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_var() {
    local APPNAME=${1-}
    local appname
    local AppName
    local VarFile
    local VarType
    local VarName
    local DescriptionHeading
    local VarNameMaxLength=256
    local VarNamePrefix=""

    DescriptionHeading=""
    if [[ -z ${APPNAME-} ]]; then
        # No appname specified, creating a global variable in .env
        VarType="GLOBAL"
        Title="Add Global Variable"
        VarFile="${COMPOSE_ENV}"
    else
        Title="Add Application Variable"
        APPNAME="${APPNAME^^}"
        if [[ ${APPNAME} == *":" ]]; then
            # appname: specified, creating a variable in appname.env
            VarType="APPENV"
            APPNAME="${APPNAME%:}"
            appname=${APPNAME,,}
            VarFile="$(run_script 'app_env_file' "${appname}")"
        else
            # appname specified, creating an APPNAME__* variable in .env
            VarType="APP"
            appname="${APPNAME,,}"
            VarFile="${COMPOSE_ENV}"
            VarNamePrefix="${APPNAME}__"
        fi
        AppName="$(run_script 'app_nicename' "${APPNAME}")"
        local AppIsUserDefined=''
        local AppIsDisabled=''
        local AppIsDepreciated=''
        if run_script 'app_is_user_defined' "${appname}"; then
            AppIsUserDefined='Y'
        else
            if run_script 'app_is_disabled' "${appname}"; then
                AppIsDisabled='Y'
            fi
            if run_script 'app_is_depreciated' "${appname}"; then
                AppIsDepreciated='Y'
            fi
        fi
        local AppNameLabel="Application: "
        local AppNameHeading="${DC[NC]}${AppNameLabel}${DC[Heading]}${AppName}${DC[NC]}"
        if [[ ${AppIsUserDefined} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}(User Defined)${DC[NC]}"
        elif [[ ${AppIsDepreciated} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}[*DEPRECIATED*]${DC[NC]}"
        fi
        if [[ ${AppIsDisabled} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}(Disabled)${DC[NC]}"
        fi
        DescriptionHeading+="${AppNameHeading}${DC[NC]}\n"
        local AppDescription
        AppDescription="$(run_script 'app_description' "${AppName}")"
        local -i LabelWidth=${#AppNameLabel}
        local -i TextWidth=$((COLUMNS - LabelWidth - 9))
        local Indent
        Indent="$(printf "%${LabelWidth}s" "")"
        local -a AppDesciption
        readarray -t AppDesciption < <(fmt -w ${TextWidth} <<< "${AppDescription}")
        DescriptionHeading+="$(printf "${Indent}${DC[HeadingAppDescription]}%s${DC[NC]}\n" "${AppDesciption[@]-}")"
        DescriptionHeading+="\n"

    fi
    local FilenameHeading="       File: ${DC[Heading]}${VarFile}${DC[NC]}"
    DescriptionHeading="${DescriptionHeading}\n${FilenameHeading}"
    local InputValueText="${DescriptionHeading}\n\nEnter the name of the variable to create\n"
    case "${VarType}" in
        APP)
            local -a PossibleOptions=(
                "${APPNAME}__CONTAINER_NAME"
                "${APPNAME}__ENABLED"
                "${APPNAME}__HOSTNAME"
                "${APPNAME}__NETWORK_MODE"
                "${APPNAME}__RESTART"
                "${APPNAME}__TAG"
            )

            local APPNAME__= \
                "               ${APPNAME}__"
            local APPNAME__ENVIRONMENT_= \
                "   ${APPNAME}__ENVIRONMENT_"
            local APPNAME__PORT_= \
                "          ${APPNAME}__PORT_"
            local ${APPNAME}__VOLUME_= \
                "        ${APPNAME}__VOLUME_"

            local -a ValidOptions=(
                "${APPNAME__}"
                "${APPNAME__ENVIRONMENT_}"
                "${APPNAME__PORT_}"
                "${APPNAME__VOLUME_}"
            )
            for Option in ${PossibleOptions[@]} do
                if ! run_script 'env_var_exists' "${Option}"; then
                    PossibleOptions+=("${Options}")
                    OptionValue+=("${Option}" "")
                fi
            done
            ;;
        APPENV)
            ;;
        GLOBAL)
            ;;
    esac
    Value=""
    while true; do
        local ErrorMessage=''
        local DetectedAppName=''
        local ValueOptions
        ValueOptions=(
            "${VarNamePrefix}" 1 1
            "${Value}" 1 $((${#VarNamePrefix} + 1))
            "${VarNameMaxLength}" "${VarNameMaxLength}"
        )
        local -a InputValueDialog=(
            --stdout
            --title "${DC["Title"]}${Title}"
            --max-input 256
            --form "${InputValueText}"
            "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" 0
            "${ValueOptions[@]}"
        )
        local InputValueDialogButtonPressed=0
        Value=$(dialog "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
        case ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} in
            OK)
                # Remove leading and trailing spaces
                local Default
                Value="$(sed -e 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "${Value}")"
                case "${VarType^^}" in
                    APP)
                        Value="${Value^^}"
                        VarName="${VarNamePrefix}${Value}"
                        if ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                        else
                            DetectedAppName="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                            if [[ ${DetectedAppName} == "" ]]; then
                                ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid variable for app ${DC[Highlight]}${AppName}${DC[NC]}. It would be a global variable${DC[NC]}.\n\n Please input another variable name."
                            fi
                        fi
                        ;;
                    APPENV)
                        VarName="${Value}"
                        if ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                        fi
                        Default="''"
                        ;;
                    GLOBAL)
                        VarName="${Value}"
                        if ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name.\n\nPlease input another variable name."
                        fi
                        DetectedAppName="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                        Default="''"
                        ;;
                    *)
                        fatal "Unexpected VarType of '${VarType}' in 'menu_add_var'. Please let the devs know."
                        ;;
                esac
                if run_script 'env_var_exists' "${VarName}" "${VarFile}"; then
                    ErrorMessage="The variable ${DC[Highlight]}${VarName}${DC[NC]} already exists.\n\n Please input another variable name."
                fi
                if [[ -n ${ErrorMessage} ]]; then
                    dialog --title "${DC["TitleError"]}${Title}" --msgbox "${DescriptionHeading}\n   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}\n\n${ErrorMessage}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                    continue
                fi
                local Question
                Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                if [[ ${VarType} == "GLOBAL" && ${DetectedAppName} != "" ]]; then
                    Question="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid global variable. It would be a variable for an app named ${DC[Highlight]}${DetectedAppName}${DC[NC]}.\n\n Do you still want to create variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                elif [[ ${VarType} == "APP" && ${DetectedAppName} != "${AppName}" ]]; then
                    Question="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid variable for app ${DC[Highlight]}${AppName}${DC[NC]}. It would be a variable for an app named ${DC[Highlight]}${DetectedAppName}${DC[NC]}.\n\n  Do you still want to create variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                fi
                if run_script 'question_prompt' N "${DescriptionHeading}\n\n   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                    if [[ ${VarType} == "APPENV" ]]; then
                        Default="$(run_script 'var_default_value' "${AppName}:${VarName}")"
                        run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${DescriptionHeading}\n\n   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}\n\n" "${DIALOGTIMEOUT}" \
                            'env_set_literal' "${appname}:${VarName}" "${Default}"
                        run_script 'menu_value_prompt' "${appname}:${VarName}"
                    else
                        Default="$(run_script 'var_default_value' "${VarName}")"
                        run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${DescriptionHeading}\n\n   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}\n\n" "${DIALOGTIMEOUT}" \
                            'env_set_literal' "${VarName}" "${Default}"
                        run_script 'menu_value_prompt' "${VarName}"
                    fi
                    return
                fi
                ;;
            CANCEL | ESC)
                return
                ;;
            *)
                if [[ -n ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} ]]; then
                    clear
                    fatal "Unexpected dialog button '${DIALOG_BUTTONS[InputValueDialogButtonPressed]}' pressed."
                else
                    clear
                    fatal "Unexpected dialog button value '${InputValueDialogButtonPressed}' pressed."
                fi
                ;;
        esac
    done
}
test_menu_add_var() {
    # run_script 'menu_add_var'
    warn "CI does not test menu_add_var."
}
