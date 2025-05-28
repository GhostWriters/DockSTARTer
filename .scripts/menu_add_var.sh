#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_add_var() {
    local APPNAME=${1-}
    local appname
    local AppName
    local VarFile
    local VarType
    local VarName=""
    local DescriptionHeading
    local VarNameMaxLength=256

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
        AppNameHeading+="\n\n"
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
    local VarNameHeading=""

    case "${VarType}" in
        APP)
            local APPNAME__CONTAINER_NAME="${APPNAME}__CONTAINER_NAME"
            local APPNAME__ENABLED="${APPNAME}__ENABLED"
            local APPNAME__HOSTNAME="${APPNAME}__HOSTNAME"
            local APPNAME__NETWORK_MODE="${APPNAME}__NETWORK_MODE"
            local APPNAME__RESTART="${APPNAME}__RESTART"
            local APPNAME__TAG="${APPNAME}__TAG"
            local APPNAME__="               ${APPNAME}__"
            local APPNAME__ENVIRONMENT_="   ${APPNAME}__ENVIRONMENT_"
            local APPNAME__PORT_="          ${APPNAME}__PORT_"
            local APPNAME__VOLUME_="        ${APPNAME}__VOLUME_"
            local -a TemplateOptions=(
                "${APPNAME__}"
                "${APPNAME__ENVIRONMENT_}"
                "${APPNAME__PORT_}"
                "${APPNAME__VOLUME_}"
            )
            local TemplateOptionsRegex
            {
                IFS='|'
                TemplateOptionsRegex="${TemplateOptions[*]}"
            }
            local -a StockOptions=(
                "${APPNAME__CONTAINER_NAME}"
                "${APPNAME__ENABLED}"
                "${APPNAME__HOSTNAME}"
                "${APPNAME__NETWORK_MODE}"
                "${APPNAME__RESTART}"
                "${APPNAME__TAG}"
            )
            local StockOptionsRegex
            {
                IFS='|'
                StockOptionsRegex="${StockOptions[*]}"
            }
            local -A OptionValue=()
            while true; do
                local VarNameHeading="   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}"
                DescriptionHeading="${AppNameHeading-}${FilenameHeading}\n\n${VarNameHeading}\n"
                local -a ValueOptions=()
                for Option in "${TemplateOptions[@]}"; do
                    ValidOptions+=("${Option}")
                    local StrippedOption="${Option// /}"
                    if [[ ${VarName} =~ ^${StrippedOption} ]]; then
                        OptionValue["${Option}"]="${VarName#"${StrippedOption}"*}"
                    else
                        OptionValue["${Option}"]=""
                    fi
                    ValueOptions+=("${Option}" "${OptionValue["${Option}"]}")
                done
                for Option in "${StockOptions[@]}"; do
                    local StrippedOption="${Option// /}"
                    if ! run_script 'env_var_exists' "${StrippedOption}"; then
                        ValidOptions+=("${Option}")
                        local StrippedOption="${Option// /}"
                        if [[ ${VarName} == "${StrippedOption}" ]]; then
                            OptionValue["${Option}"]="${StrippedOption}"
                        else
                            OptionValue["${Option}"]=""
                        fi
                        ValueOptions+=("${Option}" "${OptionValue["${Option}"]}")
                    fi
                done

                local SelectValueMenuText="${DescriptionHeading}\n\nWhat variable would you like create for application ${DC[Highlight]}${AppName}${DC[NC]}?"
                local SelectValueDialogParams=(
                    --stdout
                    --title "${DC["Title"]}${Title}"
                    #--item-help
                )
                local -i MenuTextLines
                MenuTextLines="$(dialog "${SelectValueDialogParams[@]}" --print-text-size "${SelectValueMenuText}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" | cut -d ' ' -f 1)"
                local -i SelectValueDialogButtonPressed=0
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
                SelectedOption=$(dialog "${SelectValueDialog[@]}") || SelectValueDialogButtonPressed=$?
                case ${DIALOG_BUTTONS[SelectValueDialogButtonPressed]-} in
                    OK) # SELECT button
                        if [[ ${SelectedOption} =~ ${StockOptionsRegex} ]]; then
                            VarName="${SelectedOption// /}"
                        fi
                        ;;
                    EXTRA) # EDIT button
                        local Option
                        Option="$(grep -o -P "^RENAMED \K(${TemplateOptionsRegex})(?= )" <<< "${SelectedOption}")"
                        if [[ ${Option} =~ ^${TemplateOptionsRegex}$ ]]; then
                            VarName="${Option// /}${SelectedOption#"RENAMED ${Option} "*}"
                        fi
                        # Convert to upper case and remove whitespace
                        VarName="$(tr -d '[:blank:]' <<< "${VarName^^}")"
                        ;;
                    CANCEL | ESC) # DONE button
                        local ErrorMessage=''
                        local DetectedAppName
                        if ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                        elif run_script 'env_var_exists' "${VarName}"; then
                            ErrorMessage="The variable ${DC[Highlight]}${VarName}${DC[NC]} already exists.\n\n Please input another variable name."
                        else
                            DetectedAppName="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                            if [[ ${DetectedAppName^^} == "" ]]; then
                                ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name for app ${DC[Highlight]}${AppName}${DC[NC]}. It would be a global variable.\n\n Please input another variable name."
                            elif [[ ${DetectedAppName^^} != "${APPNAME}" ]]; then
                                ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name for app ${DC[Highlight]}${AppName}${DC[NC]}. It would be a variable for an app named ${DC[Highlight]}${DetectedAppName}${DC[NC]}.\n\n Please input another variable name."
                            fi
                        fi
                        if [[ -n ${ErrorMessage-} ]]; then
                            dialog \
                                --title "${DC["TitleError"]}${Title}" \
                                --msgbox "${DescriptionHeading}\n\n${ErrorMessage}" \
                                "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                            continue
                        fi
                        Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]} for application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                        if run_script 'question_prompt' N "${DescriptionHeading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                            Default="$(run_script 'var_default_value' "${VarName}")"
                            run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${DescriptionHeading}\n\n" "${DIALOGTIMEOUT}" \
                                'env_set_literal' "${VarName}" "${Default}"
                            run_script 'menu_value_prompt' "${VarName}"
                            return
                        fi
                        ;;
                esac
            done
            ;;
        APPENV | GLOBAL)
            local VarName=''
            if [[ ${VarType} == GLOBAL ]]; then
                AppNameHeading=''
            fi
            while true; do
                local InputValueText
                local VarNameHeading="   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}"
                DescriptionHeading="${AppNameHeading-}${FilenameHeading}\n\n${VarNameHeading}\n"
                if [[ ${VarType} == APPENV ]]; then
                    InputValueText="${DescriptionHeading}\n\nEnter the name of the variable to create for app ${DC[Highlight]}${AppName}${DC[NC]}\n"
                else # GLOBAL
                    InputValueText="${DescriptionHeading}\n\nEnter the name of the global variable to create\n"
                fi
                local ErrorMessage=''
                local DetectedAppName=''
                local ValueOptions
                ValueOptions=(
                    "" 1 1
                    "${VarName}" 1 1
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
                VarName=$(dialog "${InputValueDialog[@]}") || InputValueDialogButtonPressed=$?
                case ${DIALOG_BUTTONS[InputValueDialogButtonPressed]-} in
                    OK)
                        local Default
                        VarName="$(tr -d '[:blank:]' <<< "${VarName}")"
                        if ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                        elif run_script 'env_var_exists' "${VarName}" "${VarFile}"; then
                            ErrorMessage="The variable ${DC[Highlight]}${VarName}${DC[NC]} already exists.\n\n Please input another variable name."
                        elif [[ ${VarType} == GLOBAL ]]; then
                            DetectedAppName="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                            if [[ ${DetectedAppName} != "" ]]; then
                                ErrorMessage="The variable name ${DC[Highlight]}${VarName}${DC[NC]} is not a valid global variable name. It would be a variable for an app named ${DC[Highlight]}${DetectedAppName}${DC[NC]}\n\n Please input another variable name."
                            fi
                        fi
                        VarNameHeading="   Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}"
                        DescriptionHeading="${AppNameHeading-}${FilenameHeading}\n\n${VarNameHeading}\n"
                        if [[ -n ${ErrorMessage} ]]; then
                            dialog --title "${DC["TitleError"]}${Title}" --msgbox "${DescriptionHeading}\n\n${ErrorMessage}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                            continue
                        fi
                        local Question
                        Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                        if [[ ${VarType} == "APPENV" ]]; then
                            Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]} for application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                            if run_script 'question_prompt' N "${DescriptionHeading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                                Default="$(run_script 'var_default_value' "${AppName}:${VarName}")"
                                run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${DescriptionHeading}\n\n" "${DIALOGTIMEOUT}" \
                                    'env_set_literal' "${appname}:${VarName}" "${Default}"
                                run_script 'menu_value_prompt' "${appname}:${VarName}"
                                return
                            fi
                        else # GLOBAL
                            Question="Create global variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                            if run_script 'question_prompt' N "${DescriptionHeading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                                Default="$(run_script 'var_default_value' "${VarName}")"
                                run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${DescriptionHeading}\n\n" "${DIALOGTIMEOUT}" \
                                    'env_set_literal' "${VarName}" "${Default}"
                                run_script 'menu_value_prompt' "${VarName}"
                                return
                            fi
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
            ;;
    esac

}
test_menu_add_var() {
    # run_script 'menu_add_var'
    warn "CI does not test menu_add_var."
}
