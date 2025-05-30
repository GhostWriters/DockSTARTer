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
    local Heading
    local VarNameMaxLength=256
    local AppDescription DescriptionHeading
    local VarNameNone="* NONE *"
    Heading=""
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
        local AppNameLabel="   Application: "
        local AppNameHeading="${DC[NC]}${AppNameLabel}${DC[Heading]}${AppName}${DC[NC]}"
        if [[ ${AppIsUserDefined} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}(User Defined)${DC[NC]}"
        elif [[ ${AppIsDepreciated} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}[*DEPRECIATED*]${DC[NC]}"
        fi
        if [[ ${AppIsDisabled} == 'Y' ]]; then
            AppNameHeading+=" ${DC[HeadingTag]}(Disabled)${DC[NC]}"
        fi
        AppNameHeading+="\n"
        AppDescription="$(run_script 'app_description' "${AppName}")"
        local -i LabelWidth=${#AppNameLabel}
        local -i TextWidth=$((COLUMNS - LabelWidth - 9))
        local Indent
        Indent="$(printf "%${LabelWidth}s" "")"
        local -a AppDesciption
        readarray -t AppDesciption < <(fmt -w ${TextWidth} <<< "${AppDescription}")
        DescriptionHeading="$(printf "${Indent}${DC[HeadingAppDescription]}%s${DC[NC]}\n" "${AppDesciption[@]-}")\n"
    fi
    local FilenameHeading="\n          File: ${DC[Heading]}${VarFile}${DC[NC]}\n"
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
            local -A OptionHelpLine=(
                ["${APPNAME__}"]="Complete this with any variable you want."
                ["${APPNAME__ENVIRONMENT_}"]="Complete this with a var to use in the environment: section of your override. Suggest adding to env_files/${APPNAME,,}.env instead."
                ["${APPNAME__PORT_}"]="Complete this with a var to use in the ports: section of your override."
                ["${APPNAME__VOLUME_}"]="Complete this with a var to use in the volumes: section of your override."
                ["${APPNAME__CONTAINER_NAME}"]="This can be used in the container_name: section in your override."
                ["${APPNAME__ENABLED}"]="Creating this variable will cause the app to be controlled by DockSTARTer with no override needed."
                ["${APPNAME__HOSTNAME}"]="This can be used in the hostname: section of your override."
                ["${APPNAME__NETWORK_MODE}"]="This can be used in the network_mode: section of your override."
                ["${APPNAME__RESTART}"]="This can be used in the restart: section of your override."
                ["${APPNAME__TAG}"]="This can be used in the image: section of your override. Add it at the end as :\${${APPNAME__TAG// /}}"
            )
            ClearHelpLine="This will clear any variable name already entered."
            AddAllHelpLine="This will add all stock options listed below."
            local -A OptionValue=()
            while true; do
                local VarNameHeading
                if [[ -n ${VarName-} ]]; then
                    VarNameHeading="      Variable: ${DC["HeadingValue"]}${VarName}${DC[NC]}"
                else
                    VarNameHeading="      Variable: ${DC["Highlight"]}${VarNameNone}${DC[NC]}"
                fi
                Heading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading}${VarNameHeading}\n"
                local -a TemplateValueOptions ClearValueOptions EnabledValueOptions AddAllValueOptions StockValueOptions
                unset TemplateValueOptions ClearValueOptions EnabledValueOptions AddAllValueOptions StockValueOptions
                local -i OptionsLength=0
                local ValidOptions=()
                local ValidStockOptions=()
                for Option in "${TemplateOptions[@]}"; do
                    ValidOptions+=("${Option}")
                    if [[ ${#Option} -gt ${OptionsLength} ]]; then
                        OptionsLength=${#Option}
                    fi
                    local StrippedOption="${Option// /}"
                    if [[ ${VarName} =~ ^${StrippedOption} ]]; then
                        OptionValue["${Option}"]="${VarName#"${StrippedOption}"*}"
                    else
                        OptionValue["${Option}"]=""
                    fi
                    TemplateValueOptions+=("${Option}" "${OptionValue["${Option}"]}" "${OptionHelpLine["${Option}"]-}")
                done
                if run_script 'app_is_builtin' "${APPNAME}"; then
                    local Option="${APPNAME__ENABLED}"
                    local StrippedOption="${Option// /}"
                    if ! run_script 'env_var_exists' "${StrippedOption}"; then
                        ValidOptions+=("${Option}")
                        if [[ ${#Option} -gt ${OptionsLength} ]]; then
                            OptionsLength=${#Option}
                        fi
                        if [[ ${VarName} == "${StrippedOption}" ]]; then
                            OptionValue["${Option}"]="${StrippedOption}"
                        else
                            OptionValue["${Option}"]=""
                        fi
                        EnabledValueOptions+=("${Option}" "${OptionValue["${Option}"]}" "${OptionHelpLine["${Option}"]-}")
                    fi
                fi
                for Option in "${StockOptions[@]}"; do
                    local StrippedOption="${Option// /}"
                    if ! run_script 'env_var_exists' "${StrippedOption}"; then
                        ValidOptions+=("${Option}")
                        ValidStockOptions+=("${Option}")
                        if [[ ${#Option} -gt ${OptionsLength} ]]; then
                            OptionsLength=${#Option}
                        fi
                        if [[ ${VarName} == "${StrippedOption}" ]]; then
                            OptionValue["${Option}"]="${StrippedOption}"
                        else
                            OptionValue["${Option}"]=""
                        fi
                        StockValueOptions+=("${Option}" "${OptionValue["${Option}"]}" "${OptionHelpLine["${Option}"]-}")
                    fi
                done
                local Bar
                OptionClear=" CLEAR "
                Bar=$(printf "%$(((OptionsLength - ${#OptionClear} - 1) / 2))s" '' | tr ' ' '=')
                OptionClear=" ${Bar}${OptionClear}${Bar}"
                ValidOptions+=("${OptionClear}")
                ClearValueOptions+=("${OptionClear}" "" "${ClearHelpLine-}")
                local OptionAddAll=" ADD ALL "
                Bar=$(printf "%$(((OptionsLength - ${#OptionAddAll} - 1) / 2))s" '' | tr ' ' 'v')
                OptionAddAll=" ${Bar}${OptionAddAll}${Bar}"
                if [[ -n ${StockValueOptions[*]-} ]]; then
                    ValidOptions+=("${OptionAddAll}")
                    AddAllValueOptions+=("${OptionAddAll}" "" "${AddAllHelpLine-}")
                fi
                local -a ValueOptions=()
                ValueOptions=(
                    "${TemplateValueOptions[@]-}"
                    "${ClearValueOptions[@]-}"
                )
                if [[ -n ${EnabledValueOptions[*]-} ]]; then
                    ValueOptions+=("${EnabledValueOptions[@]-}"
                    )
                fi
                if [[ -n ${StockValueOptions[*]-} ]]; then
                    ValueOptions+=(
                        "${AddAllValueOptions[@]-}"
                        "${StockValueOptions[@]-}"
                    )
                fi
                local SelectValueMenuText="${Heading}\n\nWhat variable would you like create for application ${DC[Highlight]}${AppName}${DC[NC]}?"
                local SelectValueDialogParams=(
                    --stdout
                    --item-help
                    --no-hot-list
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
                        if [[ ${SelectedOption} == "${OptionClear}" ]]; then
                            VarName=""
                        elif [[ ${SelectedOption} == "${OptionAddAll}" ]]; then
                            local Question="${DC[NC]}Would you like to create the following stock variables to use in your override file?\n"
                            for Option in "${ValidStockOptions[@]}"; do
                                Question+="\n   ${DC["Highlight"]}${Option// /}${DC[NC]}"
                            done
                            Heading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading}\n"
                            if run_script 'question_prompt' N "${Heading}\n\n${Question}" "${DC["TitleWarning"]}Create Stock Variables" "" "Create" "Back"; then
                                {
                                    notice "Adding variables to ${COMPOSE_ENV}:"
                                    for Option in "${ValidStockOptions[@]}"; do
                                        local DefaultValue
                                        DefaultValue="$(run_script 'var_default_value' "${Option// /}")"
                                        notice "   ${Option// /}=${DefaultValue}"
                                        run_script 'env_set_literal' "${Option// /}" "${DefaultValue}"
                                    done
                                } |& dialog_pipe "${DC["TitleSuccess"]}Creating Stock Variables" "${Heading}" "${DIALOGTIMEOUT}"
                            fi
                            continue
                        elif [[ ${SelectedOption} =~ ${APPNAME__ENABLED}|${StockOptionsRegex} ]]; then
                            VarName="${SelectedOption// /}"
                        fi
                        ;;
                    EXTRA) # EDIT button
                        local Option
                        Option="$(grep -o -P "^RENAMED \K(${TemplateOptionsRegex})(?= )" <<< "${SelectedOption}")"
                        if [[ ${Option} =~ ^${TemplateOptionsRegex}$ ]]; then
                            local EditedValue="${SelectedOption#"RENAMED ${Option} "*}"
                            if [[ -n ${EditedValue} ]]; then
                                VarName="${Option// /}${EditedValue}"
                            else
                                VarName=""
                            fi
                        fi
                        # Convert to upper case and remove whitespace
                        VarName="$(tr -d '[:blank:]' <<< "${VarName^^}")"
                        ;;
                    CANCEL | ESC) # DONE button
                        local ErrorMessage=''
                        local DetectedAppName
                        if [[ -z ${VarName-} ]]; then
                            if run_script 'question_prompt' N "${Heading}\n\nDo you really want to cancel adding a variable?\n" "${DC["TitleWarning"]}Cancel Adding Variable" "" "Done" "Back"; then
                                # Value is empty, exit
                                return
                            fi
                            continue
                        elif ! run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
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
                                --msgbox "${Heading}\n\n${ErrorMessage}" \
                                "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                            continue
                        fi
                        Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]} for application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                        if run_script 'question_prompt' N "${Heading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                            Default="$(run_script 'var_default_value' "${VarName}")"
                            run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${Heading}\n\n" "${DIALOGTIMEOUT}" \
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
                if [[ -n ${VarName-} ]]; then
                    VarNameHeading="      Variable: ${DC["HeadingValue"]}${VarName}${DC[NC]}"
                else
                    VarNameHeading="      Variable: ${DC["Highlight"]}${VarNameNone}${DC[NC]}"
                fi
                Heading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading}${VarNameHeading}\n"
                if [[ ${VarType} == APPENV ]]; then
                    InputValueText="${Heading}\n\nWhat variable would you like create for application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                else # GLOBAL
                    InputValueText="${Heading}\n\nWhat global variable would you like create?\n"
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
                        VarNameHeading="      Variable: ${DC[HeadingValue]}${VarName}${DC[NC]}"
                        Heading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading}${VarNameHeading}\n"
                        if [[ -n ${ErrorMessage} ]]; then
                            dialog --title "${DC["TitleError"]}${Title}" --msgbox "${Heading}\n\n${ErrorMessage}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))"
                            continue
                        fi
                        local Question
                        Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                        if [[ ${VarType} == "APPENV" ]]; then
                            Question="Create variable ${DC[Highlight]}${VarName}${DC[NC]} for application ${DC[Highlight]}${AppName}${DC[NC]}?\n"
                            if run_script 'question_prompt' N "${Heading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                                Default="$(run_script 'var_default_value' "${AppName}:${VarName}")"
                                run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${Heading}\n\n" "${DIALOGTIMEOUT}" \
                                    'env_set_literal' "${appname}:${VarName}" "${Default}"
                                run_script 'menu_value_prompt' "${appname}:${VarName}"
                                return
                            fi
                        else # GLOBAL
                            Question="Create global variable ${DC[Highlight]}${VarName}${DC[NC]}?\n"
                            if run_script 'question_prompt' N "${Heading}\n\n${Question}" "${DC["TitleWarning"]}Create Variable" "" "Create" "Back"; then
                                Default="$(run_script 'var_default_value' "${VarName}")"
                                run_script_dialog "${DC["TitleSuccess"]}Creating Variable" "${Heading}\n\n" "${DIALOGTIMEOUT}" \
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
