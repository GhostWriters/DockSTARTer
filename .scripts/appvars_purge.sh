#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge() {
    local Title="Purge Variables"
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for APPNAME in ${AppList^^}; do
        local AppName
        AppName=$(run_script 'app_nicename' "${APPNAME}")

        local APPVAR_LINES
        local APPVAR_ENV_LINES
        local APP_ENV_FILE
        APP_ENV_FILE="$(run_script 'app_env_file' "${APPNAME}")"
        APPVAR_LINES=$(run_script 'appvars_lines' "${APPNAME}")
        APPVAR_ENV_LINES=$(run_script 'env_lines' "${APP_ENV_FILE}")
        if [[ -z ${APPVAR_LINES} && -z ${APPVAR_ENV_LINES} ]]; then
            if use_dialog_box; then
                dialog --title "${DC["TitleError"]}${Title}" --msgbox "${APPNAME} has no variables." 0 0
            else
                warn "Application ${AppName} has no variables."
            fi
            return
        fi

        local QUESTION
        QUESTION=$(
            cat << EOF
Would you like to purge these settings for ${AppName}?

${COMPOSE_ENV}:
${APPVAR_LINES}

${APP_ENV_FILE}:
${APPVAR_ENV_LINES}
EOF
        )
        if [[ ${CI-} == true ]] || run_script 'question_prompt' Y "${QUESTION}\n" "${DC["TitleWarning"]}${Title}" "${FORCE:+Y}"; then
            info "Purging ${AppName} .env variables."

            local -a APPVARS
            local APPVARS_REGEX

            readarray -t APPVARS < <(run_script 'appvars_list' "${APPNAME}") # Get list of app's variables in global .env file
            printf -v APPVARS_REGEX "%s|" "${APPVARS[@]}"                    # Make a string of variables seperated by "|"
            APPVARS_REGEX="${APPVARS_REGEX%|}"                               # Remove the final "| at end of the string
            # Remove variables from file
            notice "Removing variables from ${COMPOSE_ENV}:"
            for line in "${APPVARS[@]}"; do
                notice "   $line"
            done
            sed -i -E "/^\s*(${APPVARS_REGEX})\s*=/d" "${COMPOSE_ENV}" ||
                fatal "Failed to purge ${AppName} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${APPVARS_REGEX})\\\*/d\" \"${COMPOSE_ENV}\""

            if [[ -f ${APP_ENV_FILE} ]]; then
                readarray -t APPVARS < <(run_script 'env_var_list' "${APP_ENV_FILE}") # Get list of variables in appname.env file
                printf -v APPVARS_REGEX "%s|" "${APPVARS[@]}"                         # Make a string of variables seperated by "|"
                APPVARS_REGEX="${APPVARS_REGEX%|}"                                    # Remove the final "| at end of the string
                # Remove variables from file
                notice "Removing variables from ${APP_ENV_FILE}:"
                for line in "${APPVARS[@]}"; do
                    notice "   $line"
                done
                sed -i -E "/^\s*(${APPVARS_REGEX})\s*=/d" "${APP_ENV_FILE}" ||
                    fatal "Failed to purge ${AppName} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${APPVARS_REGEX})\\\*/d\" \"${APP_ENV_FILE}\""
            fi
        else
            info "Keeping ${AppName} .env variables."
        fi
    done
}

test_appvars_purge() {
    run_script 'appvars_purge' WATCHTOWER
    run_script 'env_update'
    echo "${COMPOSE_ENV}:"
    cat "${COMPOSE_ENV}"
    local EnvFile
    EnvFile="$(run_script 'app_env_file' "watchtower")"
    echo "${EnvFile}:"
    cat "${EnvFile}"
}
