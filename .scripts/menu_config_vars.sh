#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

menu_config_vars() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}

    local Title
    local AddVariableText='<ADD VARIABLE>'

    local CurrentGlobalEnvFile CurrentAppEnvFile DefaultGlobalEnvFile DefaultAppEnvFile

    local LastLineChoice=""
    while true; do
        if [[ -n ${CurrentGlobalEnvFile-} ]]; then
            rm -f "${CurrentGlobalEnvFile}" ||
                warn "Failed to remove temporary '${C["File"]}.env${NC}' file.\nFailing command: ${C["FailingCommand"]}rm -f \"${CurrentGlobalEnvFile}\""
        fi
        if [[ -n ${CurrentAppEnvFile-} ]]; then
            rm -f "${CurrentAppEnvFile}" ||
                warn "Failed to remove temporary '${C["File"]}.env.app.${appname}${NC}' file.\nFailing command: ${C["FailingCommand"]}rm -f \"${CurrentAppEnvFile}\""
        fi
        local DefaultGlobalEnvFile=''
        local DefaultAppEnvFile=''
        if [[ -n ${APPNAME-} ]]; then
            Title="Edit Application Variables"
            CurrentGlobalEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentGlobalEnvFile.XXXXXXXXXX")
            CurrentAppEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentAppEnvFile.XXXXXXXXXX")
            if ! run_script 'app_is_user_defined' "${APPNAME}"; then
                DefaultGlobalEnvFile="$(run_script 'app_instance_file' "${APPNAME}" ".env")"
                DefaultAppEnvFile="$(run_script 'app_instance_file' "${APPNAME}" ".env.app.*")"
            fi
        else
            Title="Edit Global Variables"
            CurrentGlobalEnvFile=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.CurrentGlobalEnvFile.XXXXXXXXXX")
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
        for line in "${CurrentGlobalEnvLines[@]-}"; do
            ((++LineNumber))
            CurrentValueOnLine[LineNumber]="${line}"
            local VarName
            VarName="$(grep -o -P '^\w+(?=)' <<< "${line}")"
            if [[ -n ${VarName-} ]]; then
                # Line contains a variable
                local DefaultLine
                DefaultLine="${VarName}=$(run_script 'var_default_value' "${VarName}")"
                if [[ ${line} == "${DefaultLine}" ]]; then
                    LineColor[LineNumber]="${DC[LineVar]}"
                else
                    LineColor[LineNumber]="${DC[LineModifiedVar]}"
                fi
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
                    local DefaultLine
                    DefaultLine="${VarName}=$(run_script 'var_default_value' "${APPNAME}:${VarName}")"
                    if [[ ${line} == "${DefaultLine}" ]]; then
                        LineColor[LineNumber]="${DC[LineVar]}"
                    else
                        LineColor[LineNumber]="${DC[LineModifiedVar]}"
                    fi
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
        elif [[ $((10#${LastLineChoice})) -gt ${TotalLines} ]]; then
            LastLineChoice="$(printf "%0${PadSize}d" "${TotalLines}")"
        fi
        while true; do
            local DialogHeading
            DialogHeading="$(run_script 'menu_heading' "${APPNAME-}")"
            local -a LineDialog=(
                --output-fd 1
                --extra-button
                --ok-label "Select"
                --extra-label "Remove"
                --cancel-label "Done"
                --title "${DC["Title"]}${Title}"
                --default-item "${LastLineChoice}"
                --menu "${DialogHeading}" "$((LINES - DC["WindowRowsAdjust"]))" "$((COLUMNS - DC["WindowColsAdjust"]))" -1
                "${LineOptions[@]}"
            )
            local -i LineDialogButtonPressed=0
            LineChoice=$(_dialog_ "${LineDialog[@]}") || LineDialogButtonPressed=$?
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
                    local VarName="${VarNameOnLine[LineNumber]-}"
                    if [[ -n ${VarName} ]]; then
                        local DialogHeading
                        DialogHeading="$(run_script 'menu_heading' "${APPNAME-}" "${VarName}")"
                        local CleanVarName="${VarName}"
                        if [[ ${CleanVarName} == *":"* ]]; then
                            CleanVarName="${CleanVarName#*:}"
                        fi
                        local Question="Do you really want to delete ${DC[Highlight]}${CleanVarName}${DC[NC]}?"
                        if run_script 'question_prompt' N "${DialogHeading}\n\n${Question}\n" "Delete Variable" "" "Delete" "Back"; then
                            DialogHeading="$(run_script 'menu_heading' "${APPNAME-}" "${VarName}")"
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
                                        run_script 'appvars_migrate' "${APPNAME}"
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
                            break
                        fi
                    fi
                    ;;
                CANCEL | ESC) # Done
                    return
                    ;;
                *)
                    if [[ -n ${DIALOG_BUTTONS[LineDialogButtonPressed]-} ]]; then
                        fatal "Unexpected dialog button '${DIALOG_BUTTONS[LineDialogButtonPressed]}' pressed in menu_config_vars."
                    else
                        fatal "Unexpected dialog button value '${LineDialogButtonPressed}' pressed in menu_config_apps."
                    fi
                    ;;
            esac
        done
    done
    if [[ -n ${CurrentGlobalEnvFile-} ]]; then
        rm -f "${CurrentGlobalEnvFile}" ||
            warn "Failed to remove temporary '${C["File"]}.env${NC}' file.\nFailing command: ${C["FailingCommand"]}rm -f \"${CurrentGlobalEnvFile}\""
    fi
    if [[ -n ${CurrentAppEnvFile-} ]]; then
        rm -f "${CurrentAppEnvFile}" ||
            warn "Failed to remove temporary '${C["File"]}.env.app.${appname}${NC}' file.\nFailing command: ${C["FailingCommand"]}rm -f \"${CurrentAppEnvFile}\""
    fi
}

test_menu_config_vars() {
    # run_script 'menu_config_vars'
    warn "CI does not test menu_config_vars."
}
