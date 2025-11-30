#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
    sed
)

config_set() {
    # config_set SET_VAR NEW_VAL [VAR_FILE]
    local SET_VAR=${1-}
    local NEW_VAL=${2-}
    local VAR_FILE=${3-$APPLICATION_INI_FILE}

    if [[ ${VAR_FILE} == "${APPLICATION_INI_FILE}" && ${SET_VAR} == PackageManager ]]; then
        unset 'PM'
    fi

    # https://unix.stackexchange.com/questions/422165/escape-double-quotes-in-variable/422170#422170
    NEW_VAL="$(printf "%s\n" "${NEW_VAL-}" | ${SED} -e "s/'/'\"'\"'/g" -e "1s/^/'/" -e "\$s/\$/'/")"

    if [[ ! -f ${VAR_FILE} ]]; then
        # VAR_FILE does not exist, create it
        touchfile "${VAR_FILE}"
    fi
    ${SED} -i "/^\s*${SET_VAR}\s*=/d" "${VAR_FILE}" || true
    echo "${SET_VAR}=${NEW_VAL}" >> "${VAR_FILE}" ||
        fatal \
            "Failed to set ${C["Var"]}${SET_VAR}=${NEW_VAL}${NC}" \
            "Failing command: ${C["FailingCommand"]} \"echo ${SET_VAR}=${NEW_VAL}\" >> \"${VAR_FILE}\""
}

test_config_set() {
    warn "CI does not test config_set."
}
