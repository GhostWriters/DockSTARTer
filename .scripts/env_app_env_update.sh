#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_app_env_update() {
    local APPNAME=${1-}
    APPNAME=${APPNAME^^}
    local FILENAME=${APPNAME,,}
    local APP_FOLDER="${TEMPLATES_FOLDER}/${FILENAME}"
    local APP_DEFAULT_ENV_FILE="${APP_FOLDER}/${FILENAME}.env"
    local APP_ENV_FILE="${APP_ENV_FOLDER}/${FILENAME}.env"

    info "Replacing current appname.env file with latest template."

    # Current appname.env file, variables only (remove whitespace before and after variable)
    local HEADING_USER_DEFINED
    local HEADING_USER_DEFINED_TITLE="${APPNAME} (User Defined)"
    printf -v HEADING_USER_DEFINED "##\n## %s\n##" "${HEADING_USER_DEFINED_TITLE}"
    local HEADING_INSTALLED=""
    if run_script 'app_is_installed' "${APPNAME}"; then
        local HEADING_TITLE="${APPNAME}"
        if run_script 'app_is_disabled' "${APPNAME}"; then
            HEADING_TITLE+=' (Disabled)'
        fi
        if run_script 'app_is_depreciated' "${APPNAME}"; then
            HEADING_TITLE+=' [*DEPRECIATED*]'
        fi
        printf -v HEADING_INSTALLED "##\n## %s\n##" "${HEADING_TITLE}"
    fi
    local -a CURRENT_ENV_LINES=()
    readarray -t CURRENT_ENV_LINES < <(run_script 'env_lines' "${APP_ENV_FILE}" || true)
    local -a UPDATED_ENV_LINES=()
    if [[ -n ${CURRENT_ENV_LINES[*]} ]]; then
        if run_script 'app_is_installed' "${APPNAME}"; then
            UPDATED_ENV_LINES=("${HEADING_INSTALLED}")
            # New appname.env file we are creating
            readarray -t -O ${#UPDATED_ENV_LINES[@]} UPDATED_ENV_LINES < <(grep -v -P '^\s*#' "${APP_DEFAULT_ENV_FILE}")
            UPDATED_ENV_LINES+=("${HEADING_USER_DEFINED}")
        else
            UPDATED_ENV_LINES=("${HEADING_USER_DEFINED}")
        fi

        notice "UPDATED_ENV_LINES=\n[\n${UPDATED_ENV_LINES[*]}\n]"

        # CURRENT_ENV_VAR_LINE["VAR"]="line"
        local -A CURRENT_ENV_VAR_LINE=()
        local -a UPDATED_ENV_LINES_STRIPPED=()
        readarray -t UPDATED_ENV_LINES_STRIPPED < <(printf '%s\n' "${UPDATED_ENV_LINES[@]}" | grep -v '^#' | grep '=')
        for line in "${UPDATED_ENV_LINES_STRIPPED[@]}" "${CURRENT_ENV_LINES[@]}"; do
            local VAR=${line%%=*}
            CURRENT_ENV_VAR_LINE[$VAR]=$line
        done

        # UPDATED_ENV_VAR_INDEX["VAR"]=index position of line in UPDATED_ENV_LINE
        local -A UPDATED_ENV_VAR_INDEX=()
        {
            local -a VAR_LINES=()
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

        # Create sorted array of vars in current .env file.  Sort `_` to the top.
#        local -a CURRENT_ENV_VARS=()
#        readarray -t CURRENT_ENV_VARS < <(printf '%s\n' "${!CURRENT_ENV_VAR_LINE[@]}" | tr "_" "." | env LC_ALL=C sort | tr "." "_")
#        # Process each variable, adding them to the updated .env array
#        for index in "${!CURRENT_ENV_VARS[@]}"; do
        for line in "${CURRENT_ENV_LINES[@]}"; do
#            local VAR=${CURRENT_ENV_VARS[$index]}
            local VAR=${line%%=*}
            if [[ -n ${UPDATED_ENV_VAR_INDEX["$VAR"]-} ]]; then
                # Variable already exists, update its value and remove it from the array
                UPDATED_ENV_LINES[${UPDATED_ENV_VAR_INDEX["$VAR"]}]=${CURRENT_ENV_VAR_LINE["$VAR"]}
                unset 'CURRENT_ENV_LINES[index]'
            fi
        done

        if [[ -n ${CURRENT_ENV_VARS[*]} ]]; then
            # There are still variables to process, add to the end of the file
            for VAR in "${CURRENT_ENV_VARS[@]}"; do
                UPDATED_ENV_LINES+=("${CURRENT_ENV_VAR_LINE[$VAR]}")
            done
        fi
    else
        if run_script 'app_is_installed' "${APPNAME}"; then
            UPDATED_ENV_LINES=("${HEADING_INSTALLED}" "" "${HEADING_USER_DEFINED}")
        else
            UPDATED_ENV_LINES=("${HEADING_USER_DEFINED}")
        fi
    fi
    local MKTEMP_ENV_UPDATED
    MKTEMP_ENV_UPDATED=$(mktemp) || fatal "Failed to create temporary update .env file.\nFailing command: ${F[C]}mktemp"
    printf '%s\n' "${UPDATED_ENV_LINES[@]}" > "${MKTEMP_ENV_UPDATED}" || fatal "Failed to write temporary ${FILENAME}.env update file."

    cp -f "${MKTEMP_ENV_UPDATED}" "${APP_ENV_FILE}" || fatal "Failed to copy file.\nFailing command: ${F[C]}cp -f \"${MKTEMP_ENV_UPDATED}\" \"${APP_ENV_FILE}\""
    rm -f "${MKTEMP_ENV_UPDATED}" || warn "Failed to remove temporary ${FILENAME}.env update file.\nFailing command: ${F[C]}rm -f \"${MKTEMP_ENV_UPDATED}\""
    run_script 'set_permissions' "${APP_ENV_FILE}"
    run_script 'env_sanitize'
    info "Environment file update complete."
}

test_env_app_env_update() {
    #run_script 'env_app_env_update' WATCHTOWER
    warn "CI does not test env_app_env_update."
}
