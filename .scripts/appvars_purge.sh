#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

appvars_purge() {
    local Title="Purge Variables"
    local AppList
    AppList=$(xargs -n 1 <<< "$*")
    for AppName in ${AppList}; do
        local APPNAME=${AppName^^}
        local appname=${APPNAME,,}

        local APPVAR_LINES
        local APPVAR_ENV_LINES
        local APP_ENV_FILE="${APP_ENV_FOLDER}/${appname}.env"
        APPVAR_LINES=$(run_script 'appvars_lines' "${APPNAME}")
        APPVAR_ENV_LINES=$(run_script 'env_lines' "${APP_ENV_FILE}")
        if [[ -z ${APPVAR_LINES} && -z ${APPVAR_ENV_LINES} ]]; then
            if [[ ${PROMPT-} == "GUI" ]]; then
                dialog --fb --clear --title "${Title}" --msgbox "${APPNAME} has no variables." 0 0
            else
                warn "${APPNAME} has no variables."
            fi
            return
        fi

        local QUESTION
        QUESTION=$(
            cat << EOF
Would you like to purge these settings for ${APPNAME}?

${COMPOSE_ENV}:
${APPVAR_LINES}

${APP_ENV_FILE}:
${APPVAR_ENV_LINES}
EOF
        )
        if [[ ${CI-} == true ]] || run_script 'question_prompt' "${PROMPT:-CLI}" Y "${QUESTION}\\n" "${Title}"; then
            info "Purging ${APPNAME} .env variables."

            local -a APPVARS
            local APPVARS_REGEX

            readarray -t APPVARS < <(run_script 'appvars_list' "${APPNAME}") # Get list of app's variables in global .env file
            printf -v APPVARS_REGEX "%s|" "${APPVARS[@]}"                    # Make a string of variables seperated by "|"
            APPVARS_REGEX="${APPVARS_REGEX%|}"                               # Remove the final "| at end of the string
            # Remove variables from file
            sed -i -E "/^\s*(${APPVARS_REGEX})\s*=/d" "${COMPOSE_ENV}" ||
                fatal "Failed to purge ${APPNAME} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${APPVARS_REGEX})\\\*/d\" \"${COMPOSE_ENV}\""

            if [[ -f ${APP_ENV_FILE} ]]; then
                readarray -t APPVARS < <(run_script 'env_var_list' "${APP_ENV_FILE}") # Get list of variables in appname.env file
                printf -v APPVARS_REGEX "%s|" "${APPVARS[@]}"                         # Make a string of variables seperated by "|"
                APPVARS_REGEX="${APPVARS_REGEX%|}"                                    # Remove the final "| at end of the string
                # Remove variables from file
                sed -i -E "/^\s*(${APPVARS_REGEX})\s*=/d" "${APP_ENV_FILE}" ||
                    fatal "Failed to purge ${APPNAME} variables.\nFailing command: ${F[C]}sed -i -E \"/^\\\*(${APPVARS_REGEX})\\\*/d\" \"${APP_ENV_FILE}\""
            fi
        else
            info "Keeping ${APPNAME} .env variables."
        fi
    done
}

test_appvars_purge() {
    run_script 'appvars_purge' WATCHTOWER
    run_script 'env_update'
    echo "${COMPOSE_ENV}:"
    cat "${COMPOSE_ENV}"
    echo "${APP_ENV_FOLDER}/watchtower.env:"
    cat "${APP_ENV_FOLDER}/watchtower.env"
}
