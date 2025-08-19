#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update() {
    if [[ -z ${PROCESS_ENV_UPDATE} ]]; then
        # Env files have already been updated, nothing to do
        return
    fi
    local ENV_LINES_FILE
    ENV_LINES_FILE=$(mktemp -t "${APPLICATION_NAME}.${FUNCNAME[0]}.ENV_LINES_FILE.XXXXXXXXXX")
    run_script 'appvars_lines' "" > "${ENV_LINES_FILE}"

    local -a UPDATED_ENV_LINES=()
    readarray -t UPDATED_ENV_LINES < <(
        run_script 'env_format_lines' "${ENV_LINES_FILE}" "${COMPOSE_ENV_DEFAULT_FILE}" ""
    )

    AppList="$(run_script 'app_list_referenced')"
    # Format the global .env file
    for appname in ${AppList,,}; do
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

    # Process all referenced appname.env files
    for appname in ${AppList,,}; do
        local APP_ENV_FILE
        APP_ENV_FILE="$(run_script 'app_env_file' "${appname}")"
        local APP_DEFAULT_ENV_FILE=""
        if ! run_script 'app_is_user_defined' "${appname}"; then
            APP_DEFAULT_ENV_FILE="$(run_script 'app_instance_file' "${appname}" ".env.app.*")"
        fi
        if [[ -n ${APP_DEFAULT_ENV_FILE} || -f ${APP_ENV_FILE} ]]; then
            # App is either added, or the user has an existing appname.env file
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
                warn "Failed to remove temporary ${C["File"]}${appname}.env${NC} update file.\nFailing command: ${C["FailingCommand"]}rm -f \"${MKTEMP_APP_ENV_UPDATED}\""
            run_script 'set_permissions' "${APP_ENV_FILE}"
        fi
    done

    #run_script 'env_sanitize'
    info "Environment file update complete."
    declare -gx PROCESS_ENV_UPDATE=''
}

test_env_update() {
    run_script 'env_update'
}
