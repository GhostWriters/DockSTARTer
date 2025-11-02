#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -rgx DEPSCHECK_FOLDER="${TEMP_FOLDER}/depcheck"

check_script() {
    local script_name=${1-}
    local script_file="${SCRIPTPATH}/.scripts/${script_name}.sh"

    [[ -f ${script_file} ]] ||
        fatal \
            "Script file '${C["File"]-}${script_file}${NC-}' not found."

    [[ -f ${DEPSCHECK_FOLDER}/${script_name} ]] &&
        return 0

    touchfile "${DEPSCHECK_FOLDER}/${script_name}"

    local -a _dependencies_list=()
    # shellcheck source=/dev/null
    source "${script_file}"
    [[ ${#_dependencies_list[@]} -eq 0 ]] &&
        return 0

    pm_check_dependencies error "${_dependencies_list[@]}" ||
        fatal \
            "Fatal error in '${C["RunningCommand"]-}${script_name}${NC-}'.\n"
}

# Script Runner Function
run_script() {
    local script_name=${1-}
    shift

    local script_file="${SCRIPTPATH}/.scripts/${script_name}.sh"

    [[ -f ${script_file} ]] ||
        fatal \
            "Script file '${C["File"]}${script_file}${NC}' not found."

    check_script "${script_name}"
    # shellcheck source=/dev/null
    source "${script_file}"
    declare -F "${script_name}" &> /dev/null ||
        fatal \
            "Function '${C["RunningCommand"]-}${script_name}${NC-}' not found in script file '${C["File"]-}${script_file}${NC-}'."
    ${script_name} "$@"
}
