#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_format_lines() {
    local ENV_FILE=${1-}
    local ENV_DEFAULT_FILE=${2-}
    local APPNAME=${3-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}

    echo "["
    local -a CURRENT_ENV_LINES=()
    readarray -t CURRENT_ENV_LINES < <(run_script 'env_lines' "${ENV_FILE}" || true)

    local -a FORMATTED_ENV_LINES=()
    if [[ -n ${APPNAME} ]] && run_script 'app_is_builtin' "${APPNAME}"; then
        # APPNAME is specified and builtin, output main heading
        local HEADING_TITLE="${APPNAME}"
        if run_script 'app_is_disabled' "${APPNAME}"; then
            HEADING_TITLE+=' (Disabled)'
        fi
        if run_script 'app_is_depreciated' "${APPNAME}"; then
            HEADING_TITLE+=' [*DEPRECIATED*]'
        fi
        local HEADING
        printf -v HEADING "##\n## %s\n##" "${HEADING_TITLE}"
        FORMATTED_ENV_LINES+=("${HEADING}")
    fi
    if [[ -n ${ENV_DEFAULT_FILE} && -f ${ENV_DEFAULT_FILE} ]]; then
        # Default file is specified and exists, add the contents verbatim
        readarray -t -O ${#FORMATTED_ENV_LINES[@]} FORMATTED_ENV_LINES < "${ENV_DEFAULT_FILE}"
        FORMATTED_ENV_LINES+=("")
    fi

    # FORMATTED_ENV_VAR_INDEX["VAR"]=index position of line in FORMATTED_ENV_LINE
    local -A FORMATTED_ENV_VAR_INDEX=()
    local -a VAR_LINES=()
    # Make an array with the contents "line number:VARIABLE" in each element
    readarray -t VAR_LINES < <(printf '%s\n' "${FORMATTED_ENV_LINES[@]}" | grep -n -o -P '^[A-Za-z0-9_]*(?=[=])' || true)
    for line in "${VAR_LINES[@]}"; do
        local index=${line%:*}
        index=$((index - 1))
        local VAR=${line#*:}
        FORMATTED_ENV_VAR_INDEX[$VAR]=$index
    done

    # Update the default variables
    for index in "${!CURRENT_ENV_LINES[@]}"; do
        local line=${CURRENT_ENV_LINES[index]}
        local VAR=${line%%=*}
        if [[ -n ${FORMATTED_ENV_VAR_INDEX["$VAR"]-} ]]; then
            # Variable already exists, update its value
            FORMATTED_ENV_LINES[${FORMATTED_ENV_VAR_INDEX["$VAR"]}]=$line
            unset 'CURRENT_ENV_VARS[index]'
        fi
    done

    if [[ -n ${CURRENT_ENV_LINES[@]} ]]; then
        # Add the "User Defined" heading
        local HEADING_TITLE="${APPNAME}"
        HEADING_TITLE+=" (User Defined)"
        local HEADING
        printf -v HEADING "##\n## %s\n##" "${HEADING_TITLE}"
        FORMATTED_ENV_LINES+=("${HEADING}")

        # Add the user defined variables
        for index in "${!CURRENT_ENV_LINES[@]}"; do
            local line=${CURRENT_ENV_LINES[index]}
            local VAR=${line%%=*}
            if [[ -n ${FORMATTED_ENV_VAR_INDEX["$VAR"]-} ]]; then
                # Variable already exists, update its value
                FORMATTED_ENV_LINES[${FORMATTED_ENV_VAR_INDEX["$VAR"]}]=$line
            else
                # Variable is new, add it
                FORMATTED_ENV_LINES+=("$line")
                FORMATTED_ENV_VAR_INDEX[$VAR]=$((${#FORMATTED_ENV_LINES[@]} - 1))
            fi
        done
        FORMATTED_ENV_LINES+=("")
    fi
    printf "%s\n" "${FORMATTED_ENV_LINES[@]}"
    echo "]"
}

test_env_format_lines() {
    #run_script 'env_format_lines' WATCHTOWER
    warn "CI does not test env_format_lines."
}
