#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_format_lines() {
    local ENV_FILE=${1-}
    local ENV_DEFAULT_FILE=${2-}
    local APPNAME=${3-}
    APPNAME=${APPNAME^^}
    local appname={APPNAME,,}

    local -a ENV_LINES_ARRAY=()
    readarray -t ENV_LINES_ARRAY < <(run_script 'env_lines' "${ENV_FILE}" || true)

    local -a FORMATTED_ENV_ARRAY=()
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
    fi
    if [[ -n ${ENV_DEFAULT_FILE} && -f ${ENV_DEFAULT_FILE} ]]; then
        # Default file is specified and exists, add the contents verbatim
        readarray -t -O ${#FORMATTED_ENV_ARRAY[@]} FORMATTED_ENV_ARRAY < "${ENV_DEFAULT_FILE}"
    fi
    

    # VAR_TO_ENV_LINE["VAR"]="line"
    local -A VAR_TO_ENV_LINE=()
    for line in $(printf '%s\n' "${FORMATTED_ENV_ARRAY[@]}" | grep -v -P '^\s*#|^\s*$' | grep '=' || true); do
        local VAR=${line%%=*}
        VAR_TO_ENV_LINE[$VAR]="$line"
    done
    
    # FORMATTED_ENV_VAR_INDEX["VAR"]=index position of line in FORMATTED_ENV_LINE
    local -A FORMATTED_ENV_VAR_INDEX
    {
        local -a VAR_LINES
        # Make an array with the contents "line number:VARIABLE" in each element
        readarray -t VAR_LINES < <(printf '%s\n' "${FORMATTED_ENV_ARRAY[@]}" | grep -n -o -P '^[A-Za-z0-9_]*(?=[=])')
        for line in "${VAR_LINES[@]}"; do
            local index=${line%:*}
            index=$((index - 1))
            local VAR=${line#*:}
            FORMATTED_ENV_VAR_INDEX[$VAR]=$index
        done
    }

    # Create sorted array of vars in current .env file.  Sort `_` to the top.
    local -a CURRENT_ENV_VARS
    readarray -t CURRENT_ENV_VARS < <(printf '%s\n' "${!VAR_TO_ENV_LINE[@]}" | tr "_" "." | env LC_ALL=C sort | tr "." "_")

    # Process each variable, replacing any exising variables in the formatted .env file
    for index in "${!CURRENT_ENV_VARS[@]}"; do
        if [[ -n ${FORMATTED_ENV_VAR_INDEX["$VAR"]-} ]]; then
            # Variable already exists, update its value
            FORMATTED_ENV_ARRAY[${FORMATTED_ENV_VAR_INDEX["$VAR"]}]=${VAR_TO_ENV_LINE["$VAR"]}
            unset 'CURRENT_ENV_VARS[index]'
        fi
    done

    # Add the "User Defined" heading
    local HEADING_TITLE="${APPNAME}"
    HEADING_TITLE+="(User Defined)"
    local HEADING
    printf -v HEADING "##\n## %s\n##" "${HEADING_TITLE}"
    FORMATTED_ENV_ARRAY+=("${HEADING}")

    for VAR in "${CURRENT_ENV_VARS[@]}"; do
        # There are still variables to process, add to the end of the file
        FORMATTED_ENV_ARRAY+=("${VAR_TO_ENV_LINE[$VAR]}")
        #FORMATTED_ENV_VAR_INDEX[$VAR]=$((${#FORMATTED_ENV_ARRAY[@]} - 1))
    done
}

test_env_format_lines() {
    #run_script 'env_format_lines' WATCHTOWER
    warn "CI does not test env_format_lines."
}
