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
        unset_flags
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
                    continue
                    ;;

                # --command
                -e | --env) ;&
                -i | --install) ;&
                -l | --list) ;&
                --list-builtin) ;&
                --list-deprecated) ;&
                --list-nondeprecated) ;&
                --list-added) ;&
                --list-enabled) ;&
                --list-disabled) ;&
                --list-referenced) ;&
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

                # --command [ --command ]
                -h | --help)
                    CurrentCommand+=("${OPTION}")
                    if [[ -n ${!OPTIND-} && ${!OPTIND} == "-"* ]]; then
                        CurrentCommand+=("${!OPTIND}")
                        OPTIND+=1
                    fi
                    break
                    ;;

                # --command param
                -t | --test)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        cmdline_error \
                            "${OPTION}" \
                            "Command %c requires a script name." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}" "${!OPTIND}")
                    OPTIND+=1
                    break
                    ;;

                -M | --menu)
                    CurrentCommand=("${OPTION}")
                    if [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; then
                        local MenuCommand=${!OPTIND}
                        case "${MenuCommand,,}" in
                            main) ;&
                            config) ;&
                            config-apps | apps) ;&
                            config-app-select | app-select | select) ;&
                            config-global | global) ;&
                            options) ;&
                            options-display | display) ;&
                            options-theme | theme)
                                CurrentCommand+=("${MenuCommand}")
                                OPTIND+=1
                                ;;
                            *)
                                cmdline_error \
                                    "${OPTION}" \
                                    "Invalid menu option %o" \
                                    "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${!OPTIND}"
                                exit 1
                                ;;
                        esac
                    fi
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
                    local Command="${OPTION%%=*}="
                    local Param="${OPTION#*=}"
                    if [[ -z ${Param} ]]; then
                        cmdline_error \
                            "${Command}" \
                            "Command %c requires a variable name." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}")
                    break
                    ;;

                # --command=parameter1,[paremeter2]
                --env-set=* | env-set-lower=*)
                    local Command="${OPTION%%=*}="
                    local Param="${OPTION#*=}"
                    if [[ ${Param} != *","* ]]; then
                        cmdline_error \
                            "${Command}" \
                            "Command %c requires a variable name and a value." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}")
                    break
                    ;;

                # --command param1=[param2]
                --env-set | --env-set-lower)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} != *"="* ]]; then
                        cmdline_error \
                            "${OPTION}" \
                            "Command %c requires a variable name and a value." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}" "${!OPTIND}")
                    OPTIND+=1
                    break
                    ;;

                # --command param1 ...
                -a | --add) ;&
                --env-appvars | --env-appvars-lines) ;&
                -s | --status) ;&
                --status-enable | --status-disable)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        cmdline_error \
                            "${OPTION}" \
                            "Command %c requires one or more application names." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                        exit 1
                    fi
                    CurrentCommand+=("${OPTION}")
                    while [[ -n ${!OPTIND-} && ${!OPTIND} != "-"* ]]; do
                        CurrentCommand+=("${!OPTIND}")
                        OPTIND+=1
                    done
                    break
                    ;;
                --env-get | --env-get-lower) ;&
                --env-get-line | --env-get-lower-line) ;&
                --env-get-literal | --env-get-lower-literal)
                    if [[ -z ${!OPTIND-} || ${!OPTIND} == "-"* ]]; then
                        cmdline_error \
                            "${OPTION}" \
                            "Command %c requires one or more variable names." \
                            "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
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
                                cmdline_error \
                                    "${OPTION}" \
                                    "Invalid compose option %o" \
                                    "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${!OPTIND}"
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
                    cmdline_error \
                        "" \
                        "Invalid option %o" \
                        "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "-${OPTARG}"
                    exit 1
                    ;;
                *)
                    # Unknown '--option'
                    cmdline_error \
                        "" \
                        "Invalid option %o" \
                        "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${OPTION}"
                    exit 1
                    ;;
            esac
        done

        if [[ OPTIND -eq 1 && -n ${!OPTIND-} ]]; then
            # Unknown 'option'
            local PreviousArgsString
            PreviousArgsString="${APPLICATION_COMMAND} $(xargs <<< "${ParsedArgs[@]-}")"
            PreviousArgsString="$(xargs <<< "${PreviousArgsString}")"
            cmdline_error \
                "" \
                "Invalid option %o" \
                "${ParsedArgs[@]}" "${CurrentFlags[@]}" "${CurrentCommand[@]}" "${!OPTIND}"
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
        local CommandLineString
        CommandLineString="$(quote_elements_with_spaces "${APPLICATION_COMMAND}" "${CurrentFlags[@]}" "${CurrentCommand[@]}")"
        notice "${APPLICATION_NAME} command: '${C["UserCommand"]-}${CommandLineString}${NC-}'"
        run_command ${#CurrentFlags[@]} ${#CurrentCommand[@]} "${CurrentArgs[@]}" "$@"
    done
    return
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
    FullCommandString="$(quote_elements_with_spaces "${APPLICATION_COMMAND}" "${FullCommand[@]}")"

    local Command="${CommandArray[0]-}"
    local EqualsParam
    if [[ ${Command} == *"="* ]]; then
        # Command="--command=param"
        # Extract the parameter into EqualsParam, and strip it from Command
        EqualsParam="${Command#*=}"
        Command="${Command%%=*}="
    fi

    local -a ParamsArray=("${CommandArray[@]:1}")
    local SubTitleCommandString="${DC["NC"]-} ${DC["CommandLine"]-}${FullCommandString}"

    if [[ -z ${Command-} ]]; then
        Command="--menu"
    fi

    # Set the flags passed
    set_flags "${Flags[@]}"

    local -A \
        CommandScript \
        CommandRequireDialog CommandUseDialog \
        CommandTitle CommandSubTitle CommandNotice \
        CommandEnvBackup CommandEnvCreate CommandEnvUpdate \
        CommandUpperCase \
        CommandConfigVar CommandConfigValue

    local -A \
        MenuCommandScript \
        MenuCommandEnvBackup MenuCommandEnvCreate MenuCommandEnvUpdate \
        MenuCommandUpperCase

    CommandScript+=(
        ["-a"]="appvars_create"
        ["--add"]="appvars_create"
        ["-c"]="docker_compose"
        ["--compose"]="docker_compose"
        ["-e"]="appvars_create_all"
        ["--env"]="appvars_create_all"
        ["--env-appvars"]="appvars_list"
        ["--env-appvars-lines"]="appvars_lines"
        ["--env-get"]="env_get"
        ["--env-get-lower"]="env_get"
        ["--env-get-line"]="env_get_line"
        ["--env-get-lower-line"]="env_get_line"
        ["--env-get-literal"]="env_get_literal"
        ["--env-get-lower-literal"]="env_get_literal"
        ["--env-get="]="env_get"
        ["--env-get-lower="]="env_get"
        ["--env-get-line="]="env_get_line"
        ["--env-get-lower-line="]="env_get_line"
        ["--env-get-literal="]="env_get_literal"
        ["--env-get-lower-literal="]="env_get_literal"
        ["--env-set"]="env_set"
        ["--env-set="]="env_set"
        ["--env-set-lower"]="env_set"
        ["--env-set-lower="]="env_set"
        ["-i"]="run_install"
        ["--install"]="run_install"
        ["--list"]="app_list"
        ["-p"]="docker_prune"
        ["--prune"]="docker_prune"
        ["-r"]="appvars_purge"
        ["--remove"]="appvars_purge"
        ["-R"]="reset_needs"
        ["--reset"]="reset_needs"
        ["-s"]="app_status"
        ["--status"]="app_status"
        ["-S"]="menu_app_select"
        ["--select"]="menu_app_select"
        ["--status-disable"]="disable_app"
        ["--status-enable"]="enable_app"
        ["--list-builtin"]="app_list_builtin"
        ["--list-deprecated"]="app_list_deprecated"
        ["--list-nondeprecated"]="app_list_nondeprecated"
        ["--list-added"]="app_list_added"
        ["--list-enabled"]="app_list_enabled"
        ["--list-disabled"]="app_list_disabled"
        ["--list-referenced"]="app_list_referenced"
        ["--theme-list"]="theme_list"
        ["--theme-table"]="theme_table"
    )
    MenuCommandScript+=(
        ["main"]="menu_main"
        ["config"]="menu_config"
        ["config-apps"]="menu_config_apps"
        ["apps"]="menu_config_apps"
        ["config-global"]="menu_config_vars"
        ["global"]="menu_config_vars"
        ["config-app-select"]="menu_app_select"
        ["select"]="menu_app_select"
        ["app-select"]="menu_app_select"
        ["options"]="menu_options"
        ["options-display"]="menu_options_display"
        ["display"]="menu_options_display"
        ["options-theme"]="menu_options_theme"
        ["theme"]="menu_options_theme"
        ["env"]="menu_config_vars"
    )
    MenuCommandEnvCreate+=(
        ["global"]=1
    )
    MenuCommandEnvBackup+=(
        ["global"]=1
    )
    CommandRequireDialog+=(
        ["-S"]=1
        ["--select"]=1
    )

    CommandUseDialog+=(
        ["-a"]=1
        ["--add"]=1
        ["-e"]=1
        ["--env"]=1
        ["--list"]=1
        ["-r"]=1
        ["--remove"]=1
        ["--theme-list"]=1
        ["--theme-table"]=1
    )

    CommandTitle+=(
        ["-a"]="Add Application"
        ["--add"]="Add Application"
        ["-e"]="${DC["TitleSuccess"]-}Creating environment variables for added apps"
        ["--env"]="${DC["TitleSuccess"]-}Creating environment variables for added apps"
        ["--env-appvars"]="Variables for Application"
        ["--env-appvars-lines"]="Variable lines for Application"
        ["--env-get"]="Get Value of Variable"
        ["--env-get-lower"]="Get Value of Variable"
        ["--env-get-line"]="Get Line of Variable"
        ["--env-get-lower-line"]="Get Line of Variable"
        ["--env-get-literal"]="Get Literal Value of Variable"
        ["--env-get-lower-literal"]="Get Literal Value of Variable"
        ["--env-get="]="Get Value of Variable"
        ["--env-get-lower="]="Get Value of Variable"
        ["--env-get-line="]="Get Line of Variable"
        ["--env-get-lower-line="]="Get Line of Variable"
        ["--env-get-literal="]="Get Literal Value of Variable"
        ["--env-get-lower-literal="]="Get Literal Value of Variable"
        ["--env-set"]="Set Value of Variable"
        ["--env-set-lower"]="Set Value of Variable"
        ["--list"]="List All Applications"
        ["--list-builtin"]="List Builtin Applications"
        ["--list-deprecated"]="List Deprecated Applications"
        ["--list-nondeprecated"]="List Non-Deprecated Applications"
        ["--list-added"]="List Added Applications"
        ["--list-enabled"]="List Enabled Applications"
        ["--list-disabled"]="List Disabled Applications"
        ["--list-referenced"]="List Referenced Applications"
        ["-r"]="Remove Application"
        ["--remove"]="Remove Application"
        ["-R"]="Resetting ${APPLICATION_NAME} to process all actions."
        ["--reset"]="Resetting ${APPLICATION_NAME} to process all actions."
        ["-s"]="Application Status"
        ["--status"]="Application Status"
        ["--theme-shadows"]="Turned on shadows"
        ["--theme-no-shadows"]="Turned off shadows"
        ["--theme-scrollbar"]="Turned on scrollbars"
        ["--theme-no-scrollbar"]="Turned off scrollbars"
        ["--theme-lines"]="Turned on line drawing"
        ["--theme-no-lines"]="Turned off line drawing"
        ["--theme-borders"]="Turned on borders"
        ["--theme-no-borders"]="Turned off borders"
        ["--theme-list"]="List Themes"
        ["--theme-table"]="List Themes"
    )

    CommandSubTitle+=(
        ["-e"]="Please be patient, this can take a while.\n${SubTitleCommandString}"
        ["--env"]="Please be patient, this can take a while.\n${SubTitleCommandString}"
    )

    CommandNotice+=(
        ["--theme-shadows"]="Turning on GUI shadows."
        ["--theme-no-shadows"]="Turning off GUI shadows."
        ["--theme-scrollbar"]="Turning on GUI scrollbars."
        ["--theme-no-scrollbar"]="Turning off GUI scrollbars."
        ["--theme-lines"]="Turning on GUI line drawing characters."
        ["--theme-no-lines"]="Turning off GUI line drawing characters."
        ["--theme-borders"]="Turning on GUI borders."
        ["--theme-no-borders"]="Turning off GUI borders."
    )

    CommandConfigVar+=(
        ["--theme-shadows"]="Shadow"
        ["--theme-no-shadows"]="Shadow"
        ["--theme-scrollbar"]="Scrollbar"
        ["--theme-no-scrollbar"]="Scrollbar"
        ["--theme-lines"]="LineCharacters"
        ["--theme-no-lines"]="LineCharacters"
        ["--theme-borders"]="Borders"
        ["--theme-no-borders"]="Borders"
    )

    CommandConfigValue=(
        ["--theme-shadows"]="yes"
        ["--theme-no-shadows"]="no"
        ["--theme-scrollbar"]="yes"
        ["--theme-no-scrollbar"]="no"
        ["--theme-lines"]="yes"
        ["--theme-no-lines"]="no"
        ["--theme-borders"]="yes"
        ["--theme-no-borders"]="no"
    )
    CommandEnvCreate+=(
        ["--list-disabled"]=1
        ["--list-enabled"]=1
        ["-r"]=1
        ["--remove"]=1
        ["-s"]=1
        ["--status"]=1
    )

    CommandEnvBackup+=(
        ["-a"]=1
        ["--add"]=1
        ["-r"]=1
        ["--remove"]=1
        ["--env-set"]=1
        ["--env-set-lower"]=1
        ["--env-set="]=1
        ["--env-set-lower="]=1
        ["--status-disable"]=1
        ["--status-enable"]=1
    )

    CommandEnvUpdate+=(
        ["-a"]=1
        ["--add"]=1
        ["-r"]=1
        ["--remove"]=1
        ["--status-disable"]=1
        ["--status-enable"]=1
    )

    CommandUpperCase+=(
        ["--env-get"]=1
        ["--env-get-line"]=1
        ["--env-get-literal"]=1
        ["--env-get="]=1
        ["--env-get-line="]=1
        ["--env-get-literal="]=1
        ["--env-set"]=1
        ["--env-set="]=1
    )

    local Script="${CommandScript["${Command}"]-}"
    local RequireDialog="${CommandRequireDialog["${Command}"]-}"
    local UseDialog="${CommandUseDialog["${Command}"]-}"
    local EnvBackup="${CommandEnvBackup["${Command}"]-}"
    local EnvCreate="${CommandEnvCreate["${Command}"]-}"
    local EnvUpdate="${CommandEnvUpdate["${Command}"]-}"
    local Title="${CommandTitle["${Command}"]-${APPLICATION_NAME}}"
    local SubTitle="${CommandSubTitle["${Command}"]-${SubTitleCommandString}}"
    local Notice="${CommandNotice["${Command}"]-}"
    local UpperCase="${CommandUpperCase["${Command}"]-}"
    local ConfigVar="${CommandConfigVar["${Command}"]-}"
    local ConfigValue="${CommandConfigValue["${Command}"]-}"

    # Execute the command passed
    local -i result=0
    case "${Command}" in
        -h | --help)
            usage "${ParamsArray[0]-}"
            ;;

        -t | --test)
            run_test "${ParamsArray[0]}"
            result=$?
            ;;

        -u | --update)
            run_script 'update_self' "${ParamsArray[0]-}" "${RestOfArgs[@]}"
            result=$?
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

        -M | --menu)
            local -l MenuCommand=${ParamsArray[0]-main}
            local Script="${MenuCommandScript["${MenuCommand}"]-}"
            local EnvBackup="${MenuCommandEnvBackup["${MenuCommand}"]-}"
            local EnvCreate="${MenuCommandEnvCreate["${MenuCommand}"]-}"
            local EnvUpdate="${MenuCommandEnvUpdate["${MenuCommand}"]-}"
            local UpperCase="${MenuCommandUpperCase["${MenuCommand}"]-}"
            if [[ -z ${DIALOG-} ]]; then
                fatal \
                    "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed.\n" \
                    "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies.\n" \
                    "\n" \
                    "Unable to start GUI without the '${C["Program"]-}dialog${NC-}' command.\n"
            fi

            if [[ ${#ParamsArray[@]} -gt 1 ]]; then
                # --menu MenuCommand Parameter ...
                case "${MenuCommand}" in
                    app) ;;
                    env | env-lower) ;;
                esac
            else
                # --menu MenuCommand
                local Script=${MenuCommandScript["${MenuCommand}"]-}
                case "${MenuCommand}" in
                    main) ;&
                    config) ;&
                    config-apps | apps) ;&
                    config-app-select | app-select | select) ;&
                    config-global | global) ;&
                    options) ;&
                    options-display | display) ;&
                    options-theme | theme)
                        if [[ -z ${Script} ]]; then
                            fatal \
                                "No script is defined for menu command '${C["UserCommand"]-}${MenuCommand}${NC-}'.\n" \
                                "Please let the dev know."
                        fi
                        if [[ -n ${EnvCreate-} ]]; then
                            run_script 'env_create'
                        fi
                        if [[ -n ${EnvBackup-} ]]; then
                            run_script 'env_backup'
                        fi
                        declare -gx PROMPT="GUI"
                        run_script "${Script}"
                        result=$?
                        if [[ -n ${EnvUpdate-} ]]; then
                            run_script 'env_update'
                        fi
                        ;;
                esac
            fi
            ;;
        -a | --add) ;&
        -c | --compose) ;&
        -e | --env) ;&
        -i | --install) ;&
        --list) ;&
        --menu-config) ;&
        --menu-config-global) ;&
        --menu-app-select | --menu-config-app-select) ;&
        --menu-display | --menu-display-display | --menu-display-theme) ;&
        -p | --prune) ;&
        -r | --remove) ;&
        -R | --reset) ;&
        -s | --status) ;&
        -S | --select) ;&
        --status-disable | --status-enable) ;&
        --theme-list | --theme-table)
            if [[ -z ${Script} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            if [[ -n ${EnvCreate-} ]]; then
                run_script 'env_create'
            fi
            if [[ -n ${EnvBackup-} ]]; then
                run_script 'env_backup'
            fi
            if [[ ${RequireDialog-} ]]; then
                if [[ -z ${DIALOG-} ]]; then
                    fatal \
                        "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed.\n" \
                        "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies.\n" \
                        "\n" \
                        "Unable to start GUI without the '${C["Program"]-}dialog${NC-}' command.\n"
                fi
                declare -gx PROMPT="GUI"
                run_script "${Script}" "${ParamsArray[@]-}"
                result=$?
            else
                if [[ ${UseDialog} ]]; then
                    run_script_dialog "${Title}" "${SubTitle}" "" \
                        "${Script}" "${ParamsArray[@]-}"
                    result=$?
                else
                    run_script "${Script}" "${ParamsArray[@]-}"
                    result=$?
                fi
            fi
            if [[ -n ${EnvUpdate-} ]]; then
                run_script 'env_update'
            fi
            ;;

        --menu-config-app)
            if [[ -z ${Script} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            [[ -z ${DIALOG-} ]] && fatal \
                "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed.\n" \
                "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies.\n" \
                "\n" \
                "Unable to start GUI without the '${C["Program"]-}dialog${NC-}' command.\n"
            declare -gx PROMPT="GUI"
            local AppName="${ParamsArray[0]-}"
            if [[ -z ${AppName} ]]; then
                run_script "${Script}"
                result=$?
            else
                if ! run_script 'appname_is_valid' "${AppName}"; then
                    error "'${AppName}' is not a valid application name."
                    exit 1
                fi
                if ! run_script 'app_is_referenced' "${AppName}"; then
                    error "'${AppName}' is not installed."
                    exit 1
                fi
                run_script 'env_update'
                run_script 'menu_config_vars' "${ParamsArray[0]-}"
                result=$?
            fi
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
            if [[ -z ${ConfigVar-} || ${ConfigValue-} ]]; then
                fatal \
                    "The configuration variable and value are not defined for command '${C["UserCommand"]-}${C["UserCommand"]-}${Command}${NC-}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            if [[ -n ${Notice-} ]]; then
                notice "${Notice}"
            fi
            run_script 'config_set' "${ConfigVar}" "${ConfigValue}" "${MENU_INI_FILE}"
            result=$?
            if use_dialog_box; then
                run_script 'menu_dialog_example' "${Title}" "${FullCommandString}"
            fi
            ;;

        --env-appvars | --env-appvars-lines)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            if use_dialog_box; then
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script "${Script}" "${AppName}"
                done |& dialog_pipe "${Title}" "${SubTitle}" ""
            else
                for AppName in $(xargs -n1 <<< "${ParamsArray[0]}"); do
                    run_script "${Script}" "${AppName}"
                done
            fi
            ;;

        --env-get | --env-get-lower) ;&
        --env-get-line | --env-get-lower-line) ;&
        --env-get-literal | --env-get-lower-literal)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            [[ -n ${UpperCase} ]] && ParamsArray=("${ParamsArray[@]^^}")
            if use_dialog_box; then
                for VarName in "${ParamsArray[@]}"; do
                    run_script "${Script}" "${VarName}"
                done |& dialog_pipe "${Title}" "${SubTitle}" ""
            else
                for VarName in "${ParamsArray[@]}"; do
                    run_script "${Script}" "${VarName}"
                done
            fi
            ;;

        --env-get= | --env-get-lower=) ;&
        --env-get-line= | --env-get-lower-line=) ;&
        --env-get-literal= | --env-get-lower-literal=)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            [[ -n ${UpperCase} ]] && EqualsParam="${EqualsParam^^}"
            if use_dialog_box; then
                run_script_dialog "${Title}" "${SubTitle}" "" \
                    "${Script}" "${EqualsParam}"
            else
                run_script "${Script}" "${EqualsParam}"
            fi
            ;;

        --env-set | --env-set-lower)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            run_script 'env_backup'
            local VarName="${ParamsArray[0]%%=*}"
            local Value="${ParamsArray[0]#*=}"
            [[ -n ${UpperCase} ]] && VarName="${VarName^^}"
            run_script "${Script}" "${VarName}" "${Value}"
            run_script 'env_update'
            ;;

        --env-set=* | --env-set-lower=*)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            run_script 'env_backup'
            local VarName="${EqualsParam%%,*}"
            local Value="${EqualsParam#*,}"
            [[ -n ${UpperCase} ]] && VarName="${VarName^^}"
            run_script "${Script}" "${VarName}" "${Value}"
            run_script 'env_update'
            ;;

        --list-builtin) ;&
        --list-deprecated) ;&
        --list-nondeprecated) ;&
        --list-added) ;&
        --list-enabled) ;&
        --list-disabled) ;&
        --list-referenced)
            if [[ -z ${Script-} ]]; then
                fatal \
                    "No script is defined for command '${C["UserCommand"]-}${Command}${NC-}'.\n" \
                    "Please let the dev know."
            fi
            run_script_dialog \
                "${Title}" \
                "${SubTitle}" \
                "" \
                'app_nicename' "$(run_script "${Script}")"
            ;;

        *)
            fatal \
                "Option '${C["UserCommand"]-}${Command}${NC-}' not implemented.\n" \
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
                    warn \
                        "The '${C["UserCommand"]-}${APPLICATION_COMMAND} ${flag}${NC-}' option requires the '${C["Program"]-}dialog$}NC}' command to be installed." \
                        "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies." \
                        "\n" \
                        "Coninuing without '${C["UserCommand"]-}${flag}${NC-}' option."
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

cmdline_error() {
    # 'cmdline_error'
    # string FailingCommand, string Message, array FailingCommandLineArray
    #
    # In Message, '%c' will be replaced with FailingCommand,
    # and '%o' will be replaced with the failing option (the last element in FailingCommandLineArray)
    #
    local FailingCommand=${1}
    local Message=${2}
    shift 2
    local -a FailingCommandLineArray=("${APPLICATION_COMMAND}" "${@}")

    local FailingCommandLine FailingOption
    local FormattedFailingCommandLine FormattedFailingCommand
    local FailingMessage

    FailingCommandLine=$(
        quote_elements_with_spaces "${FailingCommandLineArray[@]:0:$((${#FailingCommandLineArray[@]} - 1))}"
    )
    FailingOption=$(
        quote_elements_with_spaces "${FailingCommandLineArray[-1]}"
    )

    FormattedFailingCommandLine="'${C["UserCommand"]-}${FailingCommandLine}${NC-} ${C["UserCommandError"]-}${FailingOption}${NC-}'"
    FormattedFailingCommand="'${C["UserCommand"]-}${FailingCommand}${NC-}'"
    FormattedFailingOption="'${C["UserCommand"]-}${FailingOption}${NC-}'"

    FailingMessage="$(
        sed "s/%c/${FormattedFailingCommand}/g ; s/%o/${FormattedFailingOption}/g" <<< "${Message}"
    )"

    error "$(
        cmdline_error_text "${FailingCommand}" "${FormattedFailingCommandLine}" "${FailingMessage}"
    )"
}

cmdline_error_text() {
    # 'cmdline_error_text'
    # string Command, string CommandLine, string Message
    local Command=${1-}
    local CommandLine=${2-}
    local Message=${3-}

    local -i Indent=3

    CommandLine="$(
        pr -e -t -o "${Indent}" <<< "${CommandLine}" | sed 's/[[:space:]]\+$//'
    )"
    Message=${Message//\\n/$'\n'}
    Message="$(
        pr -e -t -o "${Indent}" <<< "${Message}" | sed 's/[[:space:]]\+$//'
    )"

    local UsageText
    if [[ -z ${Command} ]]; then
        UsageText="Run '${C["UserCommand"]-}ds --help${NC-}' for usage."
    else
        local CommandUsage
        CommandUsage="$(usage "${Command}" NoHeading)"
        UsageText="Usage is:\n$(pr -e -t -o "${Indent}" <<< "${CommandUsage}")"
    fi
    cat << EOF
Error in command line:

${CommandLine}

${Message}

${UsageText}
EOF
}
