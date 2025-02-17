#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_format_lines() {
    local ENV_FILE=${1-}
    local ENV_DEFAULT_FILE=${2-}
    local APPNAME=${3-}
    APPNAME=${APPNAME^^}
    local appname=${APPNAME,,}

    local TOP_SECTION='false'
    notice "["
    local -a CURRENT_ENV_LINES=()
    readarray -t CURRENT_ENV_LINES < <(run_script 'env_lines' "${ENV_FILE}" || true)

    local -a FORMATTED_ENV_LINES=()
    if [[ -n ${APPNAME} ]] && run_script 'app_is_builtin' "${APPNAME}"; then
        # APPNAME is specified and builtin, output main app heading
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
        TOP_SECTION='true'
    fi
    if [[ -n ${ENV_DEFAULT_FILE} && -f ${ENV_DEFAULT_FILE} ]]; then
        # Default file is specified and exists, add the contents verbatim
        readarray -t -O ${#FORMATTED_ENV_LINES[@]} FORMATTED_ENV_LINES < "${ENV_DEFAULT_FILE}"
        TOP_SECTION='true'
    fi

    # FORMATTED_ENV_VAR_INDEX["VAR"]=index position of line in FORMATTED_ENV_LINE
    local -A FORMATTED_ENV_VAR_INDEX=()
    local -a VAR_LINES=()
    # Make an array with the contents "line number:VARIABLE" in each element
    notice $(printf '%s\n' -d'' "${FORMATTED_ENV_LINES[@]-}" | grep -n '' || true)
    readarray -t VAR_LINES < <(printf '%s\n' "${FORMATTED_ENV_LINES[@]}" | grep -z -n -o -P '^[A-Za-z0-9_]*(?=[=])' || true)
    printf '%s/n' "VAR_LINES[@]}"
    for line in "${VAR_LINES[@]}"; do
        local index=${line%:*}
        index=$((index - 1))
        local VAR=${line#*:}
        notice "line=$line, VAR=$VAR, index=$index"
        FORMATTED_ENV_VAR_INDEX[$VAR]=$index
        notice "FORMATTED_ENV_VAR_INDEX[$VAR]=$index"
    done

    if [[ -n ${CURRENT_ENV_LINES[@]-} ]]; then
        # Update the default variables
        for index in "${!CURRENT_ENV_LINES[@]}"; do
            local line=${CURRENT_ENV_LINES[index]}
            local VAR=${line%%=*}
            VAR_INDEX=${FORMATTED_ENV_VAR_INDEX["$VAR"]-}
            notice "index=$index, line=$line, VAR=$VAR, VAR_INDEX=$VAR_INDEX"
            if [[ -n ${FORMATTED_ENV_VAR_INDEX["$VAR"]-} ]]; then
                # Variable already exists, update its value
                VAR_INDEX=${FORMATTED_ENV_VAR_INDEX["$VAR"]-}
                notice "Old FORMATTED_ENV_LINES[$VAR_INDEX]=${FORMATTED_ENV_LINES[$VAR_INDEX]}"
                FORMATTED_ENV_LINES[$VAR_INDEX]=$line
                notice "New FORMATTED_ENV_LINES[$VAR_INDEX]=${FORMATTED_ENV_LINES[$VAR_INDEX]}"
                unset 'CURRENT_ENV_LINES[index]'
            fi
        done
        CURRENT_ENV_LINES=("${CURRENT_ENV_LINES[@]-}")
        if [[ -n ${CURRENT_ENV_LINES[@]-} ]]; then
            if [[ ${TOP_SECTION} == true ]]; then
                # Add a blank if there was a previous section
                FORMATTED_ENV_LINES+=("")
            fi
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
    fi
    printf "%s\n" "${FORMATTED_ENV_LINES[@]-}"
    notice "]"
}

test_env_format_lines() {
    #run_script 'env_format_lines' WATCHTOWER
    warn "CI does not test env_format_lines."
}
