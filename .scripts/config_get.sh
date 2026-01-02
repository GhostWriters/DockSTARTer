#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

config_get() {
    # config_get GET_VAR [VAR_FILE]
    local GET_VAR=${1-}
    local VAR_FILE=${2:-$APPLICATION_INI_FILE}

    if [[ -f ${VAR_FILE} ]]; then
        local Line
        local Val=""
        while IFS= read -r Line || [[ -n ${Line} ]]; do
            # Skip comments and empty lines
            [[ ${Line} =~ ^[[:space:]]*# ]] && continue
            [[ -z ${Line} ]] && continue

            # Check if line contains Key=Value
            if [[ ${Line} =~ ^[[:space:]]*${GET_VAR}[[:space:]]*= ]]; then
                # Extract Key and Value
                local Key="${Line%%=*}"
                local Value="${Line#*=}"

                # Trim whitespace from Key
                Key="${Key#"${Key%%[![:space:]]*}"}"
                Key="${Key%"${Key##*[![:space:]]}"}"

                # Check if this is the requested key
                if [[ ${Key} == "${GET_VAR}" ]]; then
                    Val="${Value}"
                    # Keep reading to get the last occurrence (tail -1 behavior)
                fi
            fi
        done < "${VAR_FILE}"

        # Trim leading whitespace
        Val="${Val#"${Val%%[![:space:]]*}"}"
        # Trim trailing whitespace
        Val="${Val%"${Val##*[![:space:]]}"}"

        # Strip single quotes if present on both ends
        if [[ ${Val} == \'*\' ]]; then
            Val="${Val#\'}"
            Val="${Val%\'}"
        # Strip double quotes if present on both ends
        elif [[ ${Val} == \"*\" ]]; then
            Val="${Val#\"}"
            Val="${Val%\"}"
        fi

        printf '%s\n' "${Val}"
    else
        # VAR_FILE does not exist, give a warning
        warn "File '${C["File"]}${VAR_FILE}${NC}' does not exist."
    fi

}

test_config_get() {
    warn "CI does not test config_get."
}
