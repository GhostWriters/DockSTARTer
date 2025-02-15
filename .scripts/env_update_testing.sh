#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_update_testing() {
    run_script 'env_backup'
    run_script 'override_backup'

    for APPNAME in $(run_script 'app_list_installed'); do
        run_script 'env_app_env_update' "${APPNAME}"
    done

    info "Replacing current .env file with latest template."

    # Current .env file, variables only (remove whitespace before and after variable)
    local -a CURRENT_ENV_LINES
    readarray -t CURRENT_ENV_LINES < <(run_script 'env_lines' "${COMPOSE_ENV}")

    # New .env file we are creating
    local -a UPDATED_ENV_LINES
    readarray -t UPDATED_ENV_LINES < "${COMPOSE_ENV_DEFAULT_FILE}"

    # CURRENT_ENV_VAR_LINE["VAR"]="line"
    local -A CURRENT_ENV_VAR_LINE
    {
        local -a UPDATED_ENV_LINES_STRIPPED
        readarray -t UPDATED_ENV_LINES_STRIPPED < <(printf '%s\n' "${UPDATED_ENV_LINES[@]}" | grep -v '^#' | grep '=')
        for line in "${UPDATED_ENV_LINES_STRIPPED[@]}" "${CURRENT_ENV_LINES[@]}"; do
            local VAR=${line%%=*}
            CURRENT_ENV_VAR_LINE[$VAR]=$line
        done
    }

    # UPDATED_ENV_VAR_INDEX["VAR"]=index position of line in UPDATED_ENV_LINE
    local -A UPDATED_ENV_VAR_INDEX
    {
        local -a VAR_LINES
        # Make an array with the contents "line number:VARIABLE" in each element
        readarray -t VAR_LINES < <(printf '%s\n' "${UPDATED_ENV_LINES[@]}" | grep -n -o -P '^[A-Za-z0-9_]*(?=[=])')
        for line in "${VAR_LINES[@]}"; do
            local index=${line%:*}
            index=$((index - 1))
            local VAR=${line#*:}
            UPDATED_ENV_VAR_INDEX[$VAR]=$index
        done
    }

    info "Merging current values into updated .env file."

    # Create array of built in apps
    local BUILTIN_APPS=()
    readarray -t BUILTIN_APPS < <(run_script 'app_list_builtin')

    # Create array of installed apps
    local INSTALLED_APPS=()
    readarray -t INSTALLED_APPS < <(run_script 'app_list_installed')

    # Create sorted array of vars in current .env file.  Sort `_` to the top.
    local -a CURRENT_ENV_VARS
    readarray -t CURRENT_ENV_VARS < <(printf '%s\n' "${!CURRENT_ENV_VAR_LINE[@]}" | tr "_" "." | env LC_ALL=C sort | tr "." "_")
    # Process each variable, adding them to the updated .env array
    while [[ -n ${CURRENT_ENV_VARS[*]} ]]; do
        # Loop while there are variables in array
        local APPNAME
        local LAST_APPNAME

        # Clear lists before processing an app's variables
        local APP_VARS=()
        local ENV_VARS_BUILTIN=()
        local ENV_VARS_USER_DEFINED=()

        # Process lines for one app
        for index in "${!CURRENT_ENV_VARS[@]}"; do
            VAR=${CURRENT_ENV_VARS[$index]}
            APPNAME=$(varname_to_appname "${VAR}")
            if [ "${APPNAME}" != "${LAST_APPNAME-}" ]; then
                # Variable for another app, exit for loop
                break
            fi
            if [[ -n ${UPDATED_ENV_VAR_INDEX["$VAR"]-} ]]; then
                # Variable already exists, update its value
                UPDATED_ENV_LINES[${UPDATED_ENV_VAR_INDEX["$VAR"]}]=${CURRENT_ENV_VAR_LINE["$VAR"]}
            else
                # Variable does not already exist, add it to a list to process
                if [[ -z ${APP_VARS[*]} ]]; then
                    # App variable array is empty, create it
                    # shellcheck disable=SC2199
                    if [[ " ${BUILTIN_APPS[@]} " == *" ${APPNAME} "* ]]; then
                        # Create array of builtin variables for current app being processed
                        local APP_VAR_FILE="${TEMPLATES_FOLDER}/${APPNAME,,}/.env"
                        readarray -t APP_VARS < <(run_script 'env_var_list' "${APP_VAR_FILE}")
                    fi
                fi
                # shellcheck disable=SC2199
                if [[ " ${APP_VARS[@]} " == *" ${VAR} "* ]]; then
                    # Variable is in variable file, add it to the built in list
                    ENV_VARS_BUILTIN+=("$VAR")
                else
                    # Variable is not in variable file, add it to the user defined list
                    ENV_VARS_USER_DEFINED+=("$VAR")
                fi
            fi
            # Remove processed var from array
            unset 'CURRENT_ENV_VARS[index]'
        done

        # Add the lines to the env file from the built in list and user defined list for the last app being processed
        local HEADING_FORMAT_BUILTIN="\n##\n## %s\n##"
        local HEADING_FORMAT_DISABLED="\n##\n## %s (Disabled)\n##"
        local HEADING_FORMAT_USER_DEFINED="\n##\n## %s (User Defined)\n##"
        local HEADING_FORMAT

        HEADING_FORMAT="${HEADING_FORMAT_BUILTIN}"
        if run_script 'app_is_disabled' "${LAST_APPNAME-}"; then
            HEADING_FORMAT="${HEADING_FORMAT_DISABLED}"
        fi
        if [[ -n ${ENV_VARS_BUILTIN-} ]]; then
            local HEADING
            # shellcheck disable=SC2059 # ${HEADING_FORMAT} contains a printf format string
            printf -v HEADING "${HEADING_FORMAT}" "${LAST_APPNAME-}"
            UPDATED_ENV_LINES+=("${HEADING}")
            for VAR in "${ENV_VARS_BUILTIN[@]}"; do
                UPDATED_ENV_LINES+=("${CURRENT_ENV_VAR_LINE[$VAR]}")
                #UPDATED_ENV_VAR_INDEX[$VAR]=$((${#UPDATED_ENV_LINES[@]} - 1))
            done
        fi
        HEADING_FORMAT="${HEADING_FORMAT_USER_DEFINED}"
        if [[ -n ${ENV_VARS_USER_DEFINED-} ]]; then
            local HEADING
            # shellcheck disable=SC2059 # ${HEADING_FORMAT} contains a printf format string
            printf -v HEADING "${HEADING_FORMAT}" "${LAST_APPNAME-}"
            UPDATED_ENV_LINES+=("${HEADING}")
            for VAR in "${ENV_VARS_USER_DEFINED[@]}"; do
                UPDATED_ENV_LINES+=("${CURRENT_ENV_VAR_LINE[$VAR]}")
                #UPDATED_ENV_VAR_INDEX[$VAR]=$((${#UPDATED_ENV_LINES[@]} - 1))
            done
        fi

        # Set last app worked on
        LAST_APPNAME=${APPNAME}
    done

    local MKTEMP_ENV_UPDATED
    MKTEMP_ENV_UPDATED=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    printf '%s\n' "${UPDATED_ENV_LINES[@]}" > "${MKTEMP_ENV_UPDATED}" || fatal "Failed to write temporary .env update file."

    cp -f "${MKTEMP_ENV_UPDATED}" "${COMPOSE_ENV}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${COMPOSE_ENV}\""
    rm -f "${MKTEMP_ENV_UPDATED}" || warn "Failed to remove temporary .env update file.\nFailing command: ${F[C]}rm -f \"${MKTEMP_ENV_UPDATED}\""
    run_script 'set_permissions' "${COMPOSE_ENV}"
    run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_update_testing() {
    run_script 'env_update_testing'
}
