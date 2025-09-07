#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
    #if ! run_script 'needs_env_update'; then
    #    # Env files have already been updated, nothing to do
    #    notice "Environment variable files already updated."
    #    return
    #fi
    notice "Updating environment variable files."

    local -al applist
    readarray -t applist < <(
        run_script 'app_list_hasvarfile'
    )
    for appname in "${applist[@]}"; do
        if ! run_script 'app_is_referenced' "${appname}"; then
            local AppEnvFile
            AppEnvFile="$(run_script 'app_env_file' "${appname}")"
            run_script 'set_permissions' "${AppEnvFile}"
            notice "Deleting '${C["File"]}${AppEnvFile}${NC}'."
            rm -f "${AppEnvFile}" ||
                warn "Failed to remove '${C["File"]}${AppEnvFile}${NC}'.\nFailing command: ${C["FailingCommand"]}rm -f \"${AppEnvFile}\""
        fi
    done

    readarray -t applist < <(
        run_script 'app_list_referenced'
    )
    # Format the global .env file
    if ! run_script 'needs_env_update' "${COMPOSE_ENV}"; then
        info "'${C["File"]}${COMPOSE_ENV}'${NC} already updated."
    else
        notice "Updating '${C["File"]}${COMPOSE_ENV}${NC}'."
        local ENV_LINES_FILE
        ENV_LINES_FILE=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ENV_LINES_FILE.XXXXXXXXXX")
        run_script 'appvars_lines' "" > "${ENV_LINES_FILE}"

        local -a UPDATED_ENV_LINES=()
        readarray -t UPDATED_ENV_LINES < <(
            run_script 'env_format_lines' "${ENV_LINES_FILE}" "${COMPOSE_ENV_DEFAULT_FILE}" ""
        )

        if [[ -n ${applist[*]-} ]]; then
            for appname in "${applist[@]}"; do
                local APP_DEFAULT_GLOBAL_ENV_FILE=""
                local -a UPDATED_APP_ENV_LINES=()
                if ! run_script 'app_is_user_defined' "${appname}"; then
                    APP_DEFAULT_GLOBAL_ENV_FILE="$(run_script 'app_instance_file' "${appname}" ".env")"
                fi
                run_script 'appvars_lines' "${appname}" > "${ENV_LINES_FILE}"
                readarray -t -O ${#UPDATED_ENV_LINES[@]} UPDATED_ENV_LINES < <(
                    run_script 'env_format_lines' "${ENV_LINES_FILE}" "${APP_DEFAULT_GLOBAL_ENV_FILE}" "${appname}"
                )
            done
        fi
        rm -f "${ENV_LINES_FILE}" ||
            warn "Failed to remove temporary '${C["File"]}.env${NC}' update file.\nFailing command: ${C["FailingCommand"]}rm -f \"${ENV_LINES_FILE}\""

        local MKTEMP_ENV_UPDATED
        MKTEMP_ENV_UPDATED=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_ENV_UPDATED.XXXXXXXXXX") ||
            fatal "Failed to create temporary update '${C["File"]}.env${NC}' file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_ENV_UPDATED.XXXXXXXXXX\""
        printf '%s\n' "${UPDATED_ENV_LINES[@]}" > "${MKTEMP_ENV_UPDATED}" || fatal "Failed to write temporary '${C["File"]}.env${NC}' update file."
        cp -f "${MKTEMP_ENV_UPDATED}" "${COMPOSE_ENV}" ||
            fatal "Failed to copy file.\nFailing command: ${C["FailingCommand"]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${COMPOSE_ENV}\""
        rm -f "${MKTEMP_ENV_UPDATED}" ||
            warn "Failed to remove temporary ${C["File"]}.env${NC} update file.\nFailing command: ${C["FailingCommand"]}rm -f \"${MKTEMP_ENV_UPDATED}\""
        run_script 'set_permissions' "${COMPOSE_ENV}"
        #run_script 'unset_needs_env_update' "${COMPOSE_ENV}"
    fi

    # Process all referenced .env.app.appname files
    if [[ -n ${applist[*]-} ]]; then
        for appname in "${applist[@]-}"; do
            local APP_ENV_FILE
            APP_ENV_FILE="$(run_script 'app_env_file' "${appname}")"
            if ! run_script 'needs_env_update' "${APP_ENV_FILE}"; then
                info "'${C["File"]}${APP_ENV_FILE}'${NC} already updated."
            else
                if [[ ! -f ${APP_ENV_FILE} ]]; then
                    notice "Creating '${C["File"]}${APP_ENV_FILE}${NC}'."
                else
                    notice "Updating '${C["File"]}${APP_ENV_FILE}${NC}'."
                fi
                local APP_DEFAULT_ENV_FILE=""
                if ! run_script 'app_is_user_defined' "${appname}"; then
                    APP_DEFAULT_ENV_FILE="$(run_script 'app_instance_file' "${appname}" ".env.app.*")"
                fi
                local -a UPDATED_APP_ENV_LINES=()
                readarray -t UPDATED_APP_ENV_LINES < <(
                    run_script 'env_format_lines' "${APP_ENV_FILE}" "${APP_DEFAULT_ENV_FILE}" "${appname}"
                )
                local MKTEMP_APP_ENV_UPDATED
                MKTEMP_APP_ENV_UPDATED=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_APP_ENV_UPDATED.XXXXXXXXXX") ||
                    fatal "Failed to create temporary update '${C["File"]}.env.app.${appname}${NC}' file.\nFailing command: ${C["FailingCommand"]}mktemp -t \"${APPLICATION_NAME}.${FUNCNAME[0]}.MKTEMP_APP_ENV_UPDATED.XXXXXXXXXX\"${NC}"
                printf '%s\n' "${UPDATED_APP_ENV_LINES[@]}" > "${MKTEMP_APP_ENV_UPDATED}" ||
                    fatal "Failed to write temporary '${C["File"]}.env.app.${appname}${NC}' update file."
                cp -f "${MKTEMP_APP_ENV_UPDATED}" "${APP_ENV_FILE}" ||
                    fatal "Failed to copy file.\nFailing command: ${C["FailingCommand"]}cp -f \"${MKTEMP_APP_ENV_UPDATED}\" \"${APP_ENV_FILE}\""
                rm -f "${MKTEMP_APP_ENV_UPDATED}" ||
                    warn "Failed to remove temporary '${C["File"]}.env.app.${appname}${NC}' update file.\nFailing command: ${C["FailingCommand"]}rm -f \"${MKTEMP_APP_ENV_UPDATED}\""
                run_script 'set_permissions' "${APP_ENV_FILE}"
                #run_script 'unset_needs_env_update' "${APP_ENV_FILE}"
            fi
        done
    fi

    #run_script 'env_sanitize'
    run_script 'unset_needs_env_update'
    info "Environment variable files update complete."
}

test_env_update() {
    run_script 'env_update'
}
