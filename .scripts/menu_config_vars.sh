#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_vars() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}
    local AppName
    AppName=$(run_script 'app_nicename' "${APPNAME}")

    local Title
    local DialogHeading
    local AddVariableText='<ADD VARIABLE>'
    local AppNameLabel="   Application: "

    local CurrentGlobalEnvFile CurrentAppEnvFile DefaultGlobalEnvFile DefaultAppEnvFile

    local LastLineChoice=""
    while true; do
        local AppNameHeading DescriptionHeading FilenameHeading VarNameHeading
        FilenameHeading=""
        if [[ -n ${CurrentGlobalEnvFile-} ]]; then
            rm -f "${CurrentGlobalEnvFile}" ||
                warn "Failed to remove temporary .env file.\nFailing command: ${F[C]}rm -f \"${CurrentGlobalEnvFile}\""
        fi
        if [[ -n ${CurrentAppEnvFile-} ]]; then
            rm -f "${CurrentAppEnvFile}" ||
                warn "Failed to remove temporary ${appname}.env file.\nFailing command: ${F[C]}rm -f \"${CurrentAppEnvFile}\""
        fi
        local DefaultGlobalEnvFile=''
        local DefaultAppEnvFile=''
        if [[ -n ${APPNAME-} ]]; then
            Title="Edit Application Variables"
            CurrentGlobalEnvFile=$(mktemp)
            CurrentAppEnvFile=$(mktemp)
            local AppIsUserDefined=''
            local AppIsDisabled=''
            local AppIsDepreciated=''
            if run_script 'app_is_user_defined' "${APPNAME}"; then
                AppIsUserDefined='Y'
            else
                DefaultGlobalEnvFile="$(run_script 'app_instance_file' "${APPNAME}" ".global.env")"
                DefaultAppEnvFile="$(run_script 'app_instance_file' "${APPNAME}" ".app.env")"
                if run_script 'app_is_disabled' "${APPNAME}"; then
                    AppIsDisabled='Y'
                fi
                if run_script 'app_is_depreciated' "${APPNAME}"; then
                    AppIsDepreciated='Y'
                fi
            fi
            AppNameHeading="${AppNameLabel}${DC[Heading]}${AppName}${DC[NC]}"
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
            DescriptionHeading="$(printf "${Indent}${DC[HeadingAppDescription]}%s${DC[NC]}\n" "${AppDesciption[@]-}")\n\n"
        else
            Title="Edit Global Variables"
            FilenameHeading="\n          File: ${DC[Heading]}${COMPOSE_ENV}${DC[NC]}\n"
            CurrentGlobalEnvFile=$(mktemp)
            DefaultGlobalEnvFile="${COMPOSE_ENV_DEFAULT_FILE}"
        fi
        local -a LineOptions=()
        local -a VarNameOnLine=()
        local -a CurrentValueOnLine=()
        local -a LineColor=()
        local -i LineNumber=0
        local FirstVarLine

        # Add lines from global .env file to the dialog
        if [[ -n ${APPNAME-} ]]; then
            ((++LineNumber))
            LineColor[LineNumber]="${DC[LineHeading]}"
            CurrentValueOnLine[LineNumber]="*** ${COMPOSE_ENV} ***"
        fi
        run_script 'appvars_lines' "${APPNAME}" > "${CurrentGlobalEnvFile}"
        local -a CurrentGlobalEnvLines
        readarray -t CurrentGlobalEnvLines < <(
            run_script 'env_format_lines' "${CurrentGlobalEnvFile}" "${DefaultGlobalEnvFile}" "${APPNAME}"
        )
        for line in "${CurrentGlobalEnvLines[@]}"; do
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="${line}"
            local VarName
            VarName="$(grep -o -P '^\w+(?=)' <<< "${line}")"
            if [[ -n ${VarName-} ]]; then
                # Line contains a variable
                LineColor[LineNumber]="${DC[LineVar]}"
                VarNameOnLine[LineNumber]="${VarName}"
                if [[ -z ${FirstVarLine-} ]]; then
                    FirstVarLine=${LineNumber}
                fi
            elif (grep -q -P '^\s*#' <<< "${line}"); then
                # Line is a comment
                LineColor[LineNumber]="${DC[LineComment]}"
            else
                # Line is an unknowwn line
                LineColor[LineNumber]="${DC[LineAddVariable]}"
            fi
        done
        ((LineNumber++))
        local AddGlobalVariableLineNumber=${LineNumber}
        CurrentValueOnLine[LineNumber]="${AddVariableText}"
        LineColor[LineNumber]="${DC[LineAddVariable]}"

        if [[ -n ${APPNAME-} ]]; then
            # Add lines from appvar.env file to the dialog
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]=""
            LineColor[LineNumber]="${DC[LineOther]}"
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="*** $(run_script 'app_env_file' "${APPNAME}") ***"
            LineColor[LineNumber]="${DC[LineHeading]}"
            run_script 'appvars_lines' "${APPNAME}:" > "${CurrentAppEnvFile}"
            local -a CurrentAppEnvLines
            readarray -t CurrentAppEnvLines < <(
                run_script 'env_format_lines' "${CurrentAppEnvFile}" "${DefaultAppEnvFile}" "${APPNAME}"
            )
            for line in "${CurrentAppEnvLines[@]}"; do
                ((++LineNumber))
                CurrentValueOnLine[LineNumber]="${line}"
                local VarName
                VarName="$(grep -o -P '^\w+(?=)' <<< "${line}")"
                if [[ -n ${VarName-} ]]; then
                    # Line contains a variable
                    LineColor[LineNumber]="${DC[LineVar]}"
                    VarNameOnLine[LineNumber]="${APPNAME}:${VarName}"
                    if [[ -z ${FirstVarLine-} ]]; then
                        FirstVarLine=${LineNumber}
                    fi
                elif (grep -q -P '^\s*#' <<< "${line}"); then
                    # Line is a comment
                    LineColor[LineNumber]="${DC[LineComment]}"
                else
                    # Line is an unknowwn line
                    LineColor[LineNumber]="${DC[LineOther]}"
                fi
            done
            ((LineNumber++))
            local AddAppEnvVariableLineNumber=${LineNumber}
            CurrentValueOnLine[LineNumber]="${AddVariableText}"
            LineColor[LineNumber]="${DC[LineAddVariable]}"
        fi

        local TotalLines=$((10#${LineNumber}))
        local PadSize=${#TotalLines}
        for LineNumber in "${!CurrentValueOnLine[@]}"; do
            local PaddedLineNumber=""
            PaddedLineNumber="$(printf "%0${PadSize}d" "${LineNumber}")"
            LineOptions+=("${PaddedLineNumber}" "${LineColor[LineNumber]-}${CurrentValueOnLine[LineNumber]}")
        done
        if [[ -z ${LastLineChoice-} ]]; then
            # Set the default line to the first line with a variable on it
            LastLineChoice="$(printf "%0${PadSize}d" "${FirstVarLine}")"
        elif [[ ${LastLineChoice} -gt ${TotalLines} ]]; then
            LastLineChoice=${TotalLines}
        fi
        while true; do
            local DialogHeading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading-}${VarNameHeading-}"
            local -a LineDialog=(
                --stdout
                --extra-button
                --ok-label "Select"
                --extra-label "Remove"
                --cancel-label "Done"
                --title "${DC["Title"]}${Title}"
                --menu "${DialogHeading}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" -1
                "${LineOptions[@]}"
            )
            local -i LineDialogButtonPressed=0
            LineChoice=$(dialog --default-item "${LastLineChoice}" "${LineDialog[@]}") || LineDialogButtonPressed=$?
            case ${DIALOG_BUTTONS[LineDialogButtonPressed]-} in
                OK) # Select
                    LastLineChoice="${LineChoice}"
                    local LineNumber
                    LineNumber=$((10#${LineChoice}))
                    if [[ ${LineNumber} == "${AddGlobalVariableLineNumber-}" ]]; then
                        run_script 'menu_add_var' "${APPNAME}"
                        break
                    elif [[ ${LineNumber} == "${AddAppEnvVariableLineNumber-}" ]]; then
                        run_script 'menu_add_var' "${APPNAME}:"
                        break
                    elif [[ -n ${VarNameOnLine[LineNumber]-} ]]; then
                        run_script 'menu_value_prompt' "${VarNameOnLine[LineNumber]}"
                        break
                    fi
                    ;;
                EXTRA) # Remove
                    LastLineChoice="${LineChoice}"
                    local LineNumber
                    LineNumber=$((10#${LineChoice}))
                    local VarName=${VarNameOnLine[LineNumber]-}
                    if [[ -n ${VarName} ]]; then
                        local CleanVarName="${VarName}"
                        local VarFile="${COMPOSE_ENV}"
                        if [[ ${CleanVarName} == *":"* ]]; then
                            CleanVarName="${CleanVarName#*:}"
                            VarFile="$(run_script 'app_env_file' "${appname}")"
                        fi
                        local FilenameHeading="          File: ${DC[Heading]}${VarFile}${DC[NC]}"
                        local DialogHeading="${AppNameHeading-}${DescriptionHeading-}${FilenameHeading-}${VarNameHeading-}"
                        local Question="Do you really want to delete ${DC[Highlight]}${CleanVarName}${DC[NC]}?"
                        if run_script 'question_prompt' N "${DialogHeading}\n\n${Question}\n" "${DC["TitleWarning"]}Delete Variable" "" "Delete" "Back"; then
                            {
                                run_script 'env_delete' "${VarName}"
                                if [[ -n ${APPNAME-} ]]; then
                                    if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                                        run_script 'env_migrate' "${APPNAME}"
                                        run_script 'appvars_create' "${APPNAME}"
                                        run_script 'env_update'
                                        run_script 'env_sanitize'
                                    fi
                                else
                                    run_script 'appvars_migrate_enabled_lines'
                                    run_script 'env_sanitize'
                                    run_script 'env_update'
                                fi
                            } |& dialog_pipe "${DC["TitleSuccess"]}Deleting Variable" "${DialogHeading}" "${DIALOGTIMEOUT}"
                            break
                        fi
                    fi
                    ;;
                CANCEL | ESC) # Done
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[LineDialogButtonPressed]-} ]]; then
                        clear
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[LineDialogButtonPressed]}' pressed."
                    else
                        clear
                        fatal "Unexpected dialog button value '${LineDialogButtonPressed}' pressed."
                    fi
                    ;;
            esac
        done
    done
    if [[ -n ${CurrentGlobalEnvFile-} ]]; then
        rm -f "${CurrentGlobalEnvFile}" ||
            warn "Failed to remove temporary .env file.\nFailing command: ${F[C]}rm -f \"${CurrentGlobalEnvFile}\""
    fi
    if [[ -n ${CurrentAppEnvFile-} ]]; then
        rm -f "${CurrentAppEnvFile}" ||
            warn "Failed to remove temporary ${appname}.env file.\nFailing command: ${F[C]}rm -f \"${CurrentAppEnvFile}\""
    fi
}

test_menu_config_vars() {
    # run_script 'menu_config_vars'
    warn "CI does not test menu_config_vars."
}
