#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

process_commands() {
    if [[ -n ${DEBUG-} ]] && [[ -n ${VERBOSE-} ]]; then
        declare -gx TRACE=1
    fi

    # Check if we're running a test
    if [[ -n ${TEST-} ]]; then
        run_script 'apply_theme'
        run_test "${TEST}"
        exit
    fi

    # Apply the GUI theme
    if [[ ${PROMPT:-CLI} == "GUI" ]]; then
        run_script 'apply_theme'
    fi

    # Execute CLI Argument Functions
    if [[ -n ${INSTALL-} ]]; then
        run_script 'run_install'
        exit
    fi
    if [[ -n ${UPDATE-} ]]; then
        if [[ ${UPDATE} == true ]]; then
            run_script 'update_self'
        else
            notice "'update_self' \"${UPDATE}\""
            run_script 'update_self' "${UPDATE}"
        fi
        exit
    fi
    if [[ -v VERSION ]]; then
        local VersionString
        VersionString="$(ds_version "${VERSION}")"
        if [[ -n ${VersionString} ]]; then
            echo "${APPLICATION_NAME} [${VersionString}]"
        else
            local Branch
            Branch="${VERSION:-$(ds_branch)}"
            error "${APPLICATION_NAME} branch '${C["Branch"]-}${Branch}${NC-}' does not exist."
        fi
        exit
    fi
    if [[ -n ${PRUNE-} ]]; then
        run_script 'docker_prune'
        exit
    fi
    if [[ -n ${THEMEMETHOD-} ]]; then
        case "${THEMEMETHOD}" in
            theme-list)
                run_script_dialog "List Themes" "" "" \
                    'theme_list'
                ;;
            theme-table)
                run_script_dialog "List Themes" "" "" \
                    'theme_table'
                ;;
            theme)
                local NoticeText
                local CommandLine
                if [[ -n ${THEME-} ]]; then
                    NoticeText="Applying ${APPLICATION_NAME} theme '${C["Theme"]-}${THEME}${NC-}'"
                    CommandLine="${APPLICATION_COMMAND} --theme \"${THEME}\""
                else
                    NoticeText="Applying ${APPLICATION_NAME} theme '${C["Theme"]-}$(run_script 'theme_name')${NC-}'"
                    CommandLine="${APPLICATION_COMMAND} --theme"
                fi
                notice "${NoticeText}"
                if use_dialog_box; then
                    run_script 'apply_theme' "${THEME-}" && run_script 'menu_dialog_example' "" "${CommandLine}"
                else
                    run_script 'apply_theme' "${THEME-}"
                fi
                ;;
            theme-shadows | theme-no-shadows) ;&
            theme-scrollbar | theme-no-scrollbar) ;&
            theme-lines | theme-no-lines) ;&
            theme-borders | theme-no-borders)
                run_script 'apply_theme'
                ;;&
            theme-shadows)
                notice "Turning on GUI shadows."
                run_script 'config_set' Shadow yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on shadows" "${APPLICATION_COMMAND} --theme-shadows"
                fi
                ;;
            theme-no-shadow)
                notice "Turning off GUI shadows."
                run_script 'config_set' Shadow no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off shadows" "${APPLICATION_COMMAND} --theme-no-shadows"
                fi
                ;;
            theme-scrollbar)
                notice "Turning on GUI scrollbars."
                run_script 'config_set' Scrollbar yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on scrollbars" "${APPLICATION_COMMAND} --theme-scrollbar"
                fi
                ;;
            theme-no-scrollbar)
                notice "Turning off GUI scrollbars."
                run_script 'config_set' Scrollbar no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off scrollbars" "${APPLICATION_COMMAND} --theme-no-scrollbar"
                fi
                ;;
            theme-lines)
                notice "Turning on GUI line drawing characters."
                run_script 'config_set' LineCharacters yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on line drawing" "${APPLICATION_COMMAND} --theme-lines"
                fi
                ;;
            theme-no-lines)
                notice "Turning off GUI line drawing characters."
                run_script 'config_set' LineCharacters no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off line drawing" "${APPLICATION_COMMAND} --theme-no-lines"
                fi
                ;;
            theme-borders)
                notice "Turning on GUI borders."
                run_script 'config_set' Borders yes "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned on borders" "${APPLICATION_COMMAND} --theme-borders"
                fi
                ;;
            theme-no-borders)
                notice "Turning off GUI borders."
                run_script 'config_set' Borders no "${MENU_INI_FILE}"
                if use_dialog_box; then
                    run_script 'menu_dialog_example' "Turned off borders" "${APPLICATION_COMMAND} --theme-no-borders"
                fi
                ;;
            *)
                error "Invalid option: '${C["UserCommand"]-}${THEMEMETHOD-}${NC-}'"
                exit 1
                ;;
        esac
        exit
    fi
    if [[ -n ${ADD-} ]]; then
        local CommandLine
        CommandLine="${APPLICATION_COMMAND} --add $(run_script 'app_nicename' "${ADD}")"
        run_script_dialog "Add Application" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}${DC["NC"]-}" "" \
            'appvars_create' "${ADD}"
        run_script 'env_update'
        exit
    fi

    # Create the '.env' file if it doesn't exists before the following command-line options
    run_script 'env_create'

    if [[ -n ${COMPOSE-} ]]; then
        case ${COMPOSE} in
            generate | merge) ;&
            down | pull | stop | restart | update | up) ;&
            "down "* | "pull "* | "stop "* | "restart "* | "update "* | "up "*)
                run_script 'docker_compose' "${COMPOSE}"
                ;;
            *)
                error "Invalid compose option '${C["UserCommand"]-}${COMPOSE}${NC-}'."
                exit 1
                ;;
        esac
        exit
    fi
    if [[ -n ${ENVMETHOD-} ]]; then
        case "${ENVMETHOD-}" in
            env)
                run_script_dialog "${DC["TitleSuccess"]-}Creating environment variables for added apps" "Please be patient, this can take a while.\n${DC["CommandLine"]-} ${APPLICATION_COMMAND} --env" "" \
                    'appvars_create_all'
                exit
                ;;
            env-get)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get VAR${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get VAR [VAR ...]${NC-}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-line ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done |& dialog_pipe "Get Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower=Var${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower Var [Var ...]${NC-}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-line ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-line${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-line VAR${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-line VAR [VAR ...]${NC-}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-line)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-line ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done |& dialog_pipe "Get Line of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_line' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-line${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-line=Var${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-line Var [Var ...]${NC-}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-get-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-literal ${ENVVAR^^}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR^^}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-literal${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-literal VAR${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-literal VAR [VAR ...]${NC-}')"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-get-lower-literal)
                if [[ ${ENVVAR-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-get-lower-literal ${ENVVAR}"
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done |& dialog_pipe "Get Literal Value of Variable" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for VarName in $(xargs -n1 <<< "${ENVVAR}"); do
                            run_script 'env_get_literal' "${VarName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-literal${NC-}' with variable name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-literal=Var${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-get-lower-literal Var [Var ...]${NC-}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-set)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR^^}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set${NC-}' with variable name and value ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set=VAR,VAL${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set VAR=Val'${NC-})"
                    echo "  Variable name will be forced to UPPER CASE"
                fi
                ;;
            env-set-lower)
                if [[ ${ENVVAR-} != "" ]] && [[ ${ENVVAL-} != "" ]]; then
                    run_script 'env_backup'
                    run_script 'env_set' "${ENVVAR}" "${ENVVAL}"
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set-lower${NC-}' with variable name and value ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set-lower=Var,VAL${NC-}' or '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-set-lower Var=Val${NC-}')"
                    echo "  Variable name can be Mixed Case"
                fi
                ;;
            env-appvars)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-appvars $(run_script 'app_nicename' "${ENVAPP}" | tr '\n' ' ')"
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_list' "${AppName}"
                        done |& dialog_pipe "Variables for Application" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP^^}"); do
                            run_script 'appvars_list' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-appvars${NC-}' with application name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-appvars App [App ...]${NC-}')"
                fi
                ;;
            env-appvars-lines)
                if [[ ${ENVAPP-} != "" ]]; then
                    if use_dialog_box; then
                        local CommandLine
                        CommandLine="${APPLICATION_COMMAND} --env-appvars-lines $(run_script 'app_nicename' "${ENVAPP}" | tr '\n' ' ')"
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done |& dialog_pipe "Variable Lines for Application" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" ""
                    else
                        for AppName in $(xargs -n1 <<< "${ENVAPP}"); do
                            run_script 'appvars_lines' "${AppName}"
                        done
                    fi
                else
                    echo "Invalid usage. Must be:"
                    echo "  '${C["UserCommand"]-}${APPLICATION_COMMAND} --env-appvars-lines${NC-}' with application name ('${C["UserCommand"]-}${APPLICATION_COMMAND} --env-appvars-lines App [App ...]'${NC-})"
                fi
                ;;
            *)
                echo "Invalid option: '${C["UserCommand"]-}${ENVMETHOD-}${NC-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${LIST-} ]]; then
        run_script_dialog "List All Applications" "" "" \
            'app_list'
        exit
    fi
    if [[ -n ${LISTMETHOD-} ]]; then
        case "${LISTMETHOD-}" in
            list-builtin)
                run_script_dialog "List Builtin Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_builtin')"
                ;;
            list-deprecated)
                run_script_dialog "List Deprecated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_deprecated')"
                ;;
            list-nondeprecated)
                run_script_dialog "List Non-Deprecated Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_nondeprecated')"
                ;;
            list-added)
                run_script_dialog "List Added Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_added')"
                ;;
            list-enabled)
                run_script_dialog "List Enabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_enabled')"
                ;;
            list-disabled)
                run_script_dialog "List Disabled Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_disabled')"
                ;;
            list-referenced)
                run_script_dialog "List Referenced Applications" "" "" \
                    'app_nicename' "$(run_script 'app_list_referenced')"
                ;;

            *)
                echo "Invalid option: '${C["UserCommand"]-}${LISTMETHOD-}${NC-}'"
                ;;
        esac
        exit
    fi
    if [[ -n ${REMOVE-} ]]; then
        if [[ ${REMOVE} == true ]]; then
            run_script 'appvars_purge_all'
            run_script 'env_update'
        else
            run_script 'appvars_purge' "${REMOVE}"
            run_script 'env_update'
        fi
        exit
    fi
    if [[ -n ${RESET-} ]]; then
        notice "Resetting ${APPLICATION_NAME} to process all actions."
        run_script 'reset_needs'
        exit 0
    fi
    if [[ -n ${SELECT-} ]]; then
        PROMPT='GUI'
        run_script 'apply_theme'
        run_script 'menu_app_select' || true
        exit
    fi
    if [[ -n ${STATUSMETHOD-} ]]; then
        case "${STATUSMETHOD-}" in
            status)
                local CommandLine
                CommandLine="${APPLICATION_COMMAND} --status $(run_script 'app_nicename' "${STATUS}" | tr '\n' ' ')"
                run_script_dialog "Application Status" "${DC["NC"]-} ${DC["CommandLine"]-}${CommandLine}" "" \
                    'app_status' "${STATUS}"
                ;;
            status-enable)
                run_script 'enable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            status-disable)
                run_script 'disable_app' "${STATUS}"
                run_script 'env_update'
                ;;
            *)
                echo "Invalid option: '${C["UserCommand"]-}${STATUSMETHOD-}${NC-}'"
                ;;
        esac
        exit
    fi
    # Run Menus
    if [[ -n ${DIALOG-} ]]; then
        PROMPT="GUI"
        run_script 'apply_theme'
        run_script 'menu_main'
    else
        error "The GUI requires the '${C["Program"]-}dialog${NC-}' command to be installed."
        error "'${C["Program"]-}dialog${NC-}' command not found. Run '${C["UserCommand"]-}${APPLICATION_COMMAND} -i${NC-}' to install all dependencies."
        fatal "Unable to start GUI without '${C["Program"]-}dialog${NC-}' command."
    fi
}
