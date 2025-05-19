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
    local VarNameMaxLength=100
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
        local AppIsUserDefined
        if run_script 'app_is_builtin' "${appname}"; then
            AppIsUserDefined=''
        else
            AppIsUserDefined='Y'
        fi
        local AppNameHeading="Application: ${DC[ColorHeading]}${AppName}${DC[NC]}"
        if [[ ${AppIsUserDefined} == 'Y' ]]; then
            AppNameHeading="${AppNameHeading} ${DC[ColorHighlight]}*User Defined*${DC[NC]}"
        fi
        DescriptionHeading="${DescriptionHeading}\n${AppNameHeading}"
    fi
    local FilenameHeading="       File: ${DC[ColorHeading]}${VarFile}${DC[NC]}"
    DescriptionHeading="${DescriptionHeading}\n${FilenameHeading}"
    local InputValueText="${DescriptionHeading}\n\nEnter the name of the variable to create\n"
    Value=""
    while true; do
        local ValueOptions
        ValueOptions=(
            "${VarNamePrefix}" 1 1
            "${Value}" 1 $((${#VarNamePrefix} + 1))
            "${VarNameMaxLength}" "${VarNameMaxLength}"
        )
        local -a InputValueDialog=(
            --stdout
            --colors
            --title "${Title}"
            --form "${InputValueText}"
            0 0 0
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
                        if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        fi
                        local VarNameApp
                        VarNameApp="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                        if [[ ${VarNameApp} == "" ]]; then
                            local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a valid variable for app ${DC[ColorHighlight]}${AppName}${DC[NC]}. It would be a global variable${DC[NC]}.\n\n Please input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        elif [[ ${VarNameApp} != "${AppName}" ]]; then
                            local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a valid variable for app ${DC[ColorHighlight]}${AppName}${DC[NC]}. It would be a variable for an app named ${DC[ColorHighlight]}${VarNameApp}${DC[NC]}.\n\n Please input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        fi
                        # Set a default value based on the variable name
                        case "${Value}" in
                            CONTAINER_NAME)
                                Default="'${appname}'"
                                ;;
                            HOSTNAME)
                                Default="'${AppName}'"
                                ;;
                            NETWORK_MODE)
                                Default="''"
                                ;;
                            RESTART)
                                Default="'unless-stopped'"
                                ;;
                            TAG)
                                Default="'latest'"
                                ;;
                            VOLUME_DOCKER_SOCKET)
                                # shellcheck disable=SC2016  # Expressions don't expand in single quotes, use double quotes for that.
                                Default='"${DOCKER_VOLUME_DOCKER_SOCKET?}"'
                                ;;
                            *)
                                if [[ ${Value} =~ PORT_[0-9]+ ]]; then
                                    Default="'${Value#PORT_*}'"
                                else
                                    Default="''"
                                fi
                                ;;
                        esac
                        ;;
                    APPENV)
                        VarName="${Value}"
                        if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a valid name.\n\n Please input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        fi
                        Default="''"
                        ;;
                    GLOBAL)
                        VarName="${Value}"
                        if run_script 'varname_is_valid' "${VarName}" "_BARE_"; then
                            local ErrorMessage="${DescriptionHeading}\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\n  The variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a name.\n\nPlease input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        fi
                        local VarNameApp
                        VarNameApp="$(run_script 'app_nicename' "$(run_script 'varname_to_appname' "${VarName}")")"
                        if [[ ${VarNameApp} != "" ]]; then
                            local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable name ${DC[ColorHighlight]}${VarName}${DC[NC]} is not a valid global variable. It would be a variable for an app named ${DC[ColorHighlight]}${VarNameApp}${DC[NC]}.\n\n Please input another variable name."
                            dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                            continue
                        fi
                        Default="''"
                        ;;
                    *)
                        fatal "Unexpected VarType of '${VarType}' in 'menu_add_var'. Please let the devs know."
                        ;;
                esac
                if run_script 'env_var_exists' "${VarName}" "${VarFile}"; then
                    local ErrorMessage="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nThe variable ${DC[ColorHighlight]}${VarName}${DC[NC]} already exists.\n\n Please input another variable name."
                    dialog --colors --title "${Title}" --msgbox "${ErrorMessage}" 0 0
                    continue
                fi
                local Question="${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\nCreate variable ${DC[ColorHighlight]}${VarName}${DC[NC]}?\n"
                if run_script 'question_prompt' N "${Question}" "Create Variable"; then
                    if [[ ${VarType} == "APPENV" ]]; then
                        run_script_dialog "Creating Variable" "${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\n" "${DIALOGTIMEOUT}" \
                            'env_set_literal' "${appname}:${VarName}" "${Default}"
                        run_script 'menu_value_prompt' "${appname}:${VarName}"
                    else
                        run_script_dialog "Creating Variable" "${DescriptionHeading}\n\n   Variable: ${DC[ColorHeadingValue]}${VarName}${DC[NC]}\n\n" "${DIALOGTIMEOUT}" \
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
