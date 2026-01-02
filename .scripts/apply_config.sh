#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

apply_config() {
    if [[ ! -f ${APPLICATION_INI_FILE} ]]; then
        run_script 'config_create'
    fi
    CONFIG_FOLDER="$(run_script 'config_get' ConfigFolder)"
    COMPOSE_FOLDER="$(run_script 'config_get' ComposeFolder)"
    CONFIG_FOLDER="$(
        ScriptFolder="${SCRIPTPATH}" \
            eval echo "\"$(cat <<< "${CONFIG_FOLDER}")\""
    )"
    COMPOSE_FOLDER="$(
        ScriptFolder="${SCRIPTPATH}" \
            eval echo "\"$(cat <<< "${COMPOSE_FOLDER}")\""
    )"
    set_global_variables
    run_script 'config_theme'
    run_script 'config_package_manager'
    sort -o "${APPLICATION_INI_FILE}" "${APPLICATION_INI_FILE}"
}

test_apply_config() {
    warn "CI does not test apply_config."
}
