#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a ParsedArgs=()

cmdline() {
    parse_arguments parse "$@"
    parse_arguments run "${ParsedArgs[@]}"
}

# Command Line Arguments
parse_arguments() {
    local mode=${1}
    shift

    if [[ ${mode} == "parse" ]]; then
        ParsedArgs=()
    fi

    if [[ -z $* ]]; then
        # No arguments on the command line, nothing to parse
        if [[ ${mode} != "parse" ]]; then
            run_command 0 0 "" ""
        fi
        return
    fi

    local -i OPTIND
    local OPTARG
    while [[ $# -gt 0 ]]; do
        declare -gx PROMPT="CLI"
        unset FORCE VERBOSE DEBUG
        local -a CurrentFlags=()
        local -a CurrentCommand=()

        while getopts ":-:acefghilMprRsStTuvVx" OPTION; do
            if [[ ${OPTION} == "-" ]]; then
                # Rename the long option to --option
                OPTION="--${OPTARG}"
            else
                # Rename the short option to -o
                OPTION="-${OPTION}"
            fi
            case ${OPTION} in
                # --flag
                -f | --force) ;&
                -g | --gui) ;&
                -v | --verbose) ;&
                -x | --debug)
                    CurrentFlags+=("${OPTION}")
                    ;;

                # --command
                -e | --env) ;&
                -h | --help) ;&
                -i | --install) ;&
                -l | --list) ;&
                --list-*) ;&
                -M | --menu) ;&
                -p | --prune) ;&
                -R | --reset) ;&
                -S | --select) ;&
                --theme-shadows | --theme-no-shadows) ;&
                --theme-scrollbar | --theme-no-scrollbar) ;&
                --theme-lines | --theme-no-lines) ;&
                --theme-borders | --theme-no-borders)
                    CurrentCommand=("${OPTION}")
                    break
                    ;;

                # --command param
                -t | --test)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        local PreviousArgsString
                        PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                        PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                        error \
                            "Error in command line:\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${OPTION}${NC-}'\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${OPTION}${NC-}' requires an option.\n" \
                            "\n" \
                            "Usage is:\n" \
                            "\n" \
                            "$(usage "${OPTION}")\n" \
                            "\n"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}" "${!OPTIND}")
                    OPTIND+=1
                    break
                    ;;

                # --command [param]
                -T | --theme) ;&
                -u | --update) ;&
                -V | --version)
                    CurrentCommand+=("${OPTION}")
                    if [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; then
                        CurrentCommand+=("${!OPTIND}")
                        OPTIND+=1
                    fi
                    break
                    ;;

                # --command=Param
                --env-get=* | --env-get-lower=*) ;&
                --env-get-line=* | --env-get-lower-line=*) ;&
                --env-get-literal=* | --env-get-lower-literal=*)
                    local Param=${OPTION%%=*}
                    if [[ -z ${Param} ]]; then
                        local Command="${OPTION%%=*}="
                        local PreviousArgsString
                        PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                        PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                        error \
                            "Error in command line:\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${Command}${NC-}'\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${Command}${NC-}' requires an option.\n" \
                            "\n" \
                            "Usage is:\n" \
                            "\n" \
                            "$(usage "${Command}")\n" \
                            "\n"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}" "${Param}")
                    break
                    ;;

                # --command=parameter1,[paremeter2]
                --env-set=* | env-set-lower=*)
                    local Command="${OPTION%%=*}="
                    local RestOfCommand=${OPTION#*=}
                    if [[ ${RestOfCommand} != *","* ]]; then
                        error \
                            "'${C["UserCommand"]-}${APPLICATION_COMMAND}${NC-} ${C["UserCommandError"]-}${Command}${NC-}' must be in form of '${C["UserCommand"]-}${APPLICATION_COMMAND} ${Command}=Param1,Param2${NC-}'\n" \
                            "\n" \
                            "Usage is:\n" \
                            "\n" \
                            "$(usage "${Command}")\n" \
                            "\n"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}")
                    break
                    ;;

                # --command param1=[param2]
                --env-set | --env-set-lower)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        local PreviousArgsString
                        PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                        PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                        error \
                            "Error in command line:\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${OPTION}${NC-}'\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${OPTION}${NC-}' requires an option.\n" \
                            "\n" \
                            "Usage is:\n" \
                            "\n" \
                            "$(usage "${OPTION}")\n" \
                            "\n"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}" "${!OPTIND}}")
                    OPTIND+=1
                    break
                    ;;

                # --command param1 ...
                -a | --add) ;&
                --env-appvars | --env-appvars-lines) ;&
                --env-get | --env-get-lower) ;&
                --env-get-line | --env-get-lower-line) ;&
                --env-get-literal | --env-get-lower-literal) ;&
                -s | --status) ;&
                --status-enable | --status-disable)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        local PreviousArgsString
                        PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                        PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                        error \
                            "Error in command line:\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${OPTION}${NC-}'\n" \
                            "\n" \
                            "   '${C["UserCommand"]-}${OPTION}${NC-}' requires an option.\n" \
                            "\n" \
                            "Usage is:\n" \
                            "\n" \
                            "$(usage "${OPTION}")\n" \
                            "\n"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}")
                    while [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; do
                        CurrentCommand+=("${!OPTIND}")
                        OPTIND+=1
                    done
                    break
                    ;;

                # --command [param ...]
                -r | --remove)
                    CurrentCommand+=("${OPTION}")
                    while [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; do
                        CurrentCommand+=("${!OPTIND}")
                        OPTIND+=1
                    done
                    break
                    ;;

                # --compose [ [down|pull|stop|restart|update|up] [param ...] ]
                -c | --compose)
                    CurrentCommand+=("${OPTION}")
                    if [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; then
                        case ${!OPTIND} in
                            generate | merge) ;&
                            down | pull | stop | restart | update | up) ;&
                            "down "* | "pull "* | "stop "* | "restart "* | "update "* | "up "*)
                                until [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; do
                                    CurrentCommand+=("${!OPTIND}")
                                    OPTIND+=1
                                done
                                ;;
                            *)
                                local PreviousArgsString
                                PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                                PreviousArgsString="$(xargs <<< "${PreviousArgsString}") ${OPTION}"
                                error \
                                    "Error in command line:\n" \
                                    "\n" \
                                    "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${!OPTIND}${NC-}'\n" \
                                    "\n" \
                                    "   Invalid compose option '${C["UserCommand"]-}${!OPTIND}${NC-}'.\n" \
                                    "\n" \
                                    "Usage is:\n" \
                                    "\n" \
                                    "$(usage "${OPTION}")\n" \
                                    "\n"
                                exit 1
                                ;;
                        esac
                    fi
                    break
                    ;;

                -\?)
                    # Unknown '-o'
                    local PreviousArgsString
                    PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                    PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                    error \
                        "Error in command line:\n" \
                        "\n" \
                        "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}-${OPTARG}${NC-}'\n" \
                        "\n" \
                        "   Invalid option '${C["UserCommand"]-}${OPTARG}${NC-}'.\n" \
                        "\n" \
                        "Run '${C["UserCommand"]-}ds --help${NC-}' for usage.\n"
                    exit 1
                    ;;
                *)
                    # Unknown '--option'
                    local PreviousArgsString
                    PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
                    PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
                    error \
                        "Error in command line:\n" \
                        "\n" \
                        "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${OPTION}${NC-}'\n" \
                        "\n" \
                        "   Invalid option '${C["UserCommand"]-}${OPTION}${NC-}'.\n" \
                        "\n" \
                        "Run '${C["UserCommand"]-}ds --help${NC-}' for usage.\n"
                    exit 1
                    ;;
            esac
        done

        if [[ OPTIND -eq 1 && -n ${!OPTIND-} ]]; then
            # Unknown 'option'
            local PreviousArgsString
            PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
            PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
            error \
                "Error in command line:\n" \
                "\n" \
                "   '${C["UserCommand"]-}${PreviousArgsString}${NC-} ${C["UserCommandError"]-}${!OPTIND-}${NC-}'\n" \
                "\n" \
                "   Invalid option '${C["UserCommand"]-}${C["UserCommand"]-}${!OPTIND-}${NC-}'.\n" \
                "\n" \
                "Run '${C["UserCommand"]-}ds --help${NC-}' for usage.\n"
            exit 1
        fi
        # Remove the arguments just processed from the argument list
        shift $((OPTIND - 1))
        OPTIND=1

        local -a CurrentArgs=("${CurrentFlags[@]}" "${CurrentCommand[@]}")
        if [[ ${mode} == parse ]]; then
            ParsedArgs+=("${CurrentArgs[@]}")
            continue
        fi

        # Execute the current command
        run_command ${#CurrentFlags[@]} ${#CurrentCommand[@]} "${CurrentArgs[@]}" "$@"
    done
    return
}

set_flags() {
    for flag in "$@"; do
        case "${flag}" in
            -f | --force)
                declare -gx FORCE=true
                ;;
            -g | --gui)
                if [[ -n ${DIALOG-} ]]; then
                    declare -gx PROMPT="GUI"
                else
                    warn "The '${C["UserCommand"]-}${APPLICATION_COMMAND} ${flag}${NC-}' option requires the '${C["Program"]-}dialog$}NC}' command to be installed."
                    warn "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies."
                    warn "Coninuing without '${C["UserCommand"]-}${flag}${NC-}' option."
                fi
                ;;
            -v | --verbose)
                declare -gx VERBOSE=1
                ;;
            -x | --debug)
                declare -gx DEBUG=1
                ;;
        esac
    done
    if [[ -n ${DEBUG-} && -n ${VERBOSE-} ]]; then
        declare -gx TRACE=1
    fi
    if [[ -n ${DEBUG-} ]]; then
        set -x
    fi
}

unset_flags() {
    set +x
    declare -gx PROMPT="CLI"
    unset FORCE VERBOSE DEBUG TRACE
}

run_command() {
    # run_command (int FlagsLength, int CommandLength, array Flags, array CommandArray, array RestOfArgs)
    local -i FlagsLength=${1}
    local -i CommandLength=${2}
    shift 2

    # Split the arguments in FullCommand (flags + command), Flags, CommandArray, and the remaining arguments
    local -i FullCommandLength
    FullCommandLength=$((FlagsLength + CommandLength))
    local -a FullCommand=("${@:1:FullCommandLength}")
    local -a Flags=("${@:1:FlagsLength}")
    shift ${FlagsLength}
    local -a CommandArray=("${@:1:CommandLength}")
    shift ${CommandLength}
    local -a RestOfArgs=("$@")
    local FullCommandString=''
    if [[ FullCommandLength -eq 0 ]]; then
        # No arguments passed, just use the applicatin command
        FullCommandString="${APPLICATION_COMMAND}"
    else
        # Quote any arguments with spaces in them
        for element in "${FullCommand[@]}"; do
            if [[ ${element} == *" "* ]]; then
                # If the element contains spaces, quote it
                FullCommandString+="\"${element}\" "
            else
                # Otherwise, add it as is
                FullCommandString+="${element} "
            fi
        done
        # Prepend the application command, and remove any trailing space.
        FullCommandString="${APPLICATION_COMMAND} ${FullCommandString% }"
    fi
    local Command="${CommandArray[0]-}"
    local -a ParamsArray=("${CommandArray[@]:1}")

    # Set the flags passed
    set_flags "${Flags[@]}"

    # Execute the command passed
    local -i result=0
    if [[ -z ${Command} || ${Command} =~ ^(-M|--menu)$ ]]; then
        # No option, -M, or --menu, load the menu system
        if [[ -z ${DIALOG-} ]]; then
            error \
                "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed.\n" \
                "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies.\n" \
                "Unable to start GUI without '${C["Program"]-}dialog${NC-}' command.\n"
            exit 1
        fi
        declare -gx PROMPT="GUI"
        run_script 'apply_theme'
        run_script 'menu_main'
        return
    fi

    case "${Command}" in
        -t | --test)
            run_script 'apply_theme'
            run_test "${ParamsArray[@]}"
            result=$?
            ;;

        *)
            # Apply the GUI theme if using the GUI before the following command line optins
            if [[ ${PROMPT:-CLI} == "GUI" ]]; then
                run_script 'apply_theme'
            fi
            ;;&

        -i | --install)
            run_script 'run_install'
            result=$?
            ;;

        -u | --update)
            if [[ -z ${CommandArray[1]-} ]]; then
                run_script 'update_self' "" "${RestOfArgs[@]}" || result=$?
                result=$?
            else
                run_script 'update_self' "${ParamsArray[0]}" "${RestOfArgs[@]}" || result=$?
                result=$?
            fi
            ;;

        -V | --version)
            local Branch="${ParamsArray[0]-}"
            if [[ -z ${Branch} ]]; then
                echo "${APPLICATION_NAME} [$(ds_version)]"
            else
                if ! ds_branch_exists "${Branch}"; then
                    error "${APPLICATION_NAME} branch '${C["Branch"]-}${Branch}${NC-}' does not exist."
                    exit 1
                fi
                echo "${APPLICATION_NAME} [$(ds_version "${Branch}")]"
            fi
            ;;

        -p | --prune)
            run_script 'docker_prune'
            result=$?
            ;;

        --theme-list)
            run_script_dialog \
                "List Themes" \
                "" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" \
                'theme_list'
            result=$?
            ;;
        --theme-table)
            run_script_dialog \
                "List Themes" \
                "" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" \
                'theme_table'
            result=$?
            ;;

        -T | --theme)
            local NoticeText
            local ThemeName=${ParamsArray[0]-}
            if [[ -n ${ThemeName} ]]; then
                NoticeText="Applying ${APPLICATION_NAME} theme '${C["Theme"]-}${ThemeName}${NC-}'"
            else
                NoticeText="Re-applying ${APPLICATION_NAME} theme '${C["Theme"]-}$(run_script 'theme_name')${NC-}'"
            fi
            notice "${NoticeText}"
            if use_dialog_box; then
                run_script 'apply_theme' "${ThemeName}" && run_script 'menu_dialog_example' "" "${FullCommandString}"
                result=$?
            else
                run_script 'apply_theme' "${ThemeName}"
                result=$?
            fi
            ;;

        --theme-shadows | --theme-no-shadows) ;&
        --theme-scrollbar | --theme-no-scrollbar) ;&
        --theme-lines | --theme-no-lines) ;&
        --theme-borders | --theme-no-borders)
            local -A CommandNotice=(
                ["--theme-shadows"]="Turning on GUI shadows."
                ["--theme-no-shadows"]="Turning off GUI shadows."
                ["--theme-scrollbar"]="Turning on GUI scrollbars."
                ["--theme-no-scrollbar"]="Turning off GUI scrollbars."
                ["--theme-lines"]="Turning on GUI line drawing characters."
                ["--theme-no-lines"]="Turning off GUI line drawing characters."
                ["--theme-borders"]="Turning on GUI borders."
                ["--theme-no-borders"]="Turning off GUI borders."
            )
            local -A CommandTitle=(
                ["--theme-shadows"]="Turned on shadows"
                ["--theme-no-shadows"]="Turned off shadows"
                ["--theme-scrollbar"]="Turned on scrollbars"
                ["--theme-no-scrollbar"]="Turned off scrollbars"
                ["--theme-lines"]="Turned on line drawing"
                ["--theme-no-lines"]="Turned off line drawing"
                ["--theme-borders"]="Turned on borders"
                ["--theme-no-borders"]="Turned off borders"
            )
            local -A CommandVar=(
                ["--theme-shadows"]="Shadow"
                ["--theme-no-shadows"]="Shadow"
                ["--theme-scrollbar"]="Scrollbar"
                ["--theme-no-scrollbar"]="Scrollbar"
                ["--theme-lines"]="LineCharacters"
                ["--theme-no-lines"]="LineCharacters"
                ["--theme-borders"]="Borders"
                ["--theme-no-borders"]="Borders"
            )
            local -A CommandValue=(
                ["--theme-shadows"]="yes"
                ["--theme-no-shadows"]="no"
                ["--theme-scrollbar"]="yes"
                ["--theme-no-scrollbar"]="no"
                ["--theme-lines"]="yes"
                ["--theme-no-lines"]="no"
                ["--theme-borders"]="yes"
                ["--theme-no-borders"]="no"
            )
            run_script 'apply_theme'
            notice "${CommandNotice["${Command}"]}"
            run_script 'config_set' \
                "${CommandVar["${Command}"]}" \
                "${CommandValue["${Command}"]}" \
                "${MENU_INI_FILE}"
            result=$?
            if use_dialog_box; then
                run_script 'menu_dialog_example' \
                    "${CommandTitle["${Command}"]}" \
                    "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}"
            fi
            ;;

        -a | --add)
            run_script_dialog \
                "Add Application" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}${DC["NC"]-}" \
                "" \
                'appvars_create' "${ParamsArray[@]}" && run_script 'env_update'
            result=$?
            ;;

        -r | --remove)
            run_script_dialog \
                "Remove Application" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}${DC["NC"]-}" \
                "" \
                'appvars_purge' "${ParamsArray[@]}" && run_script 'env_update'
            ;;

        *)
            # Create the '.env' file if it doesn't exists before the following command-line options
            run_script 'env_create'
            ;;&

        -c | --compose)
            run_script 'docker_compose' "${ParamsArray[@]}"
            result=$?
            ;;

        -e | --env)
            run_script_dialog \
                "${DC["TitleSuccess"]-}Creating environment variables for added apps" \
                "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${FullCommandString}" \
                "" \
                'appvars_create_all'
            result=$?
            ;;

        --env-get | --env-get-line | env-get-literal)
            # Force variable names to upper case
            ParamsArray=("${ParamsArray[@]^^}")
            ;;&
        --env-get | --env-get-lower)
            if use_dialog_box; then
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get' "${VarName}"
                done |& dialog_pipe "Get Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" ""
            else
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get' "${VarName}"
                done
            fi
            ;;
        --env-get-line | --env-get-lower-line)
            if use_dialog_box; then
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get_line' "${VarName}"
                done |& dialog_pipe "Get Line of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" ""
            else
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get_line' "${VarName}"
                done
            fi
            ;;
        --env-get-literal | --env-get-lower-literal)
            if use_dialog_box; then
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get_literal' "${VarName}"
                done |& dialog_pipe "Get Literal Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" ""
            else
                for VarName in "${ParamsArray[@]}"; do
                    run_script 'env_get_literal' "${VarName}"
                done
            fi
            ;;

        --env-set)
            # Force variable names to upper case
            ParamsArray[0]="${ParamsArray[0]^^}"
            ;;&
        --env-set | --env-set-lower)
            run_script 'env_backup'
            run_script 'env_set' "${ParamsArray[0]}" "${ParamsArray[1]}"
            ;;
        --env-get=* | --env-get-lower=*) ;;&
        --env-get-line=* | --env-get-lower-line=*) ;;&
        --env-get-literal=* | --env-get-lower-literal=*) ;;&
        --env-set=* | --env-set-lower=*) ;;&

        --env-appvars)
            if use_dialog_box; then
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script 'appvars_list' "${AppName}"
                done |& dialog_pipe "Variables for Application" "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" ""
            else
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script 'appvars_list' "${AppName}"
                done
            fi
            ;;
        --env-appvars-lines)
            if use_dialog_box; then
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script 'appvars_lines' "${AppName}"
                done |& dialog_pipe "Variables for Application" "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" ""
            else
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script 'appvars_list' "${AppName}"
                done
            fi
            ;;

        -h | --help)
            usage
            ;;

        --list)
            run_script_dialog \
                "List All Applications" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" \
                "" \
                'app_list'
            ;;

        --list-builtin) ;&
        --list-deprecated) ;&
        --list-nondeprecated) ;&
        --list-added) ;&
        --list-enabled) ;&
        --list-disabled) ;&
        --list-referenced)
            local -A CommandTitle=(
                ["--list-builtin"]="List Builtin Applications"
                ["--list-deprecated"]="List Deprecated Applications"
                ["--list-nondeprecated"]="List Non-Deprecated Applications"
                ["--list-added"]="List Added Applications"
                ["--list-enabled"]="List Enabled Applications"
                ["--list-disabled"]="List Disabled Applications"
                ["--list-referenced"]="List Referenced Applications"
            )
            local -A CommandScript=(
                ["--list-builtin"]="app_list_builtin"
                ["--list-deprecated"]="app_list_deprecated"
                ["--list-nondeprecated"]="app_list_nondeprecated"
                ["--list-added"]="app_list_added"
                ["--list-enabled"]="app_list_enabled"
                ["--list-disabled"]="app_list_disabled"
                ["--list-referenced"]="app_list_referenced"
            )
            run_script_dialog \
                "${CommandTitle["${Command}"]}" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" \
                "" \
                'app_nicename' "$(run_script "${CommandScript["${Command}"]}")"
            ;;

        -R | --reset)
            notice "Resetting ${APPLICATION_NAME} to process all actions."
            run_script 'reset_needs'
            ;;

        -S | --select)
            if [[ -z ${DIALOG-} ]]; then
                error \
                    "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed.\n" \
                    "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies.\n" \
                    "Unable to start GUI without '${C["Program"]-}dialog${NC-}' command.\n"
                exit 1
            fi
            declare -gx PROMPT="GUI"
            run_script 'apply_theme'
            run_script 'menu_app_select'
            result=$?
            ;;

        -s | --status)
            run_script_dialog \
                "Application Status" \
                "${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}" \
                "" \
                'app_status' "${ParamsArray[@]}"
            ;;

        --status-enable)
            run_script 'enable_app' "${ParamsArray[@]}"
            run_script 'env_update'
            ;;
        --status-disable)
            run_script 'disable_app' "${ParamsArray[@]}"
            run_script 'env_update'
            ;;

        *)
            fatal \
                "Option '${C["UserCommand"]-}${CommandArray[0]}${NC-}' not implemented.\n" \
                "Please let the dev know."
            ;;
    esac

    # Unset the flags
    unset_flags

    # Exit if the command had an error
    if [[ ${result} != 0 ]]; then
        exit ${result}
    fi
}
