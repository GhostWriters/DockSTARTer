#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx LC_ALL=C

# Environment Information
declare -rgx APPLICATION_CACHE_FOLDER="${XDG_CACHE_HOME}/${APPLICATION_NAME,,}"
mkdir -p "${APPLICATION_CACHE_FOLDER}"
sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${APPLICATION_CACHE_FOLDER}"
sudo chmod a=,a+rX,u+w,g+w "${APPLICATION_CACHE_FOLDER}"

declare -rgx TEMP_FOLDER="${APPLICATION_CACHE_FOLDER}/.temp"
if [[ -e ${TEMP_FOLDER} ]]; then
    sudo rm -rf "${TEMP_FOLDER}"
fi
mkdir -p "${TEMP_FOLDER}"
sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${TEMP_FOLDER}"
sudo chmod a=,a+rX,u+w,g+w "${TEMP_FOLDER}"

declare -gx DEFAULTS_FOLDER_NAME=".defaults"
declare -gx TEMPLATES_FOLDER_NAME=".apps"
declare -gx INSTANCES_FOLDER_NAME=".instances"
declare -gx THEME_FOLDER_NAME=".themes"
declare -gx TIMESTAMPS_FOLDER_NAME=".timestamps"
declare -gx APP_ENV_FOLDER_NAME="env_files"

declare -gx TIMESTAMPS_FOLDER="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/${TIMESTAMPS_FOLDER_NAME}"
if [[ -d ${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME} ]]; then
    # Migrate old timestamps folder
    if [[ ! -d ${TIMESTAMPS_FOLDER} ]]; then
        mv "${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME}" "${TIMESTAMPS_FOLDER}" || true
    else
        rm -rf "${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME}" || true
    fi
fi

declare -gx DEFAULTS_FOLDER="${SCRIPTPATH}/${DEFAULTS_FOLDER_NAME}"
declare -gx TEMPLATES_FOLDER="${SCRIPTPATH}/${TEMPLATES_FOLDER_NAME}"
declare -gx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -gx INSTANCES_FOLDER="${XDG_STATE_HOME}/${APPLICATION_NAME,,}/${INSTANCES_FOLDER_NAME}"
if [[ -d ${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME} ]]; then
    # Migrate old instances folder
    if [[ ! -d ${INSTANCES_FOLDER} ]]; then
        mv "${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME}" "${INSTANCES_FOLDER}" || true
    else
        rm -rf "${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME}" || true
    fi
fi

declare -gx APPLICATION_INI_FOLDER="${XDG_CONFIG_HOME}"
declare -gx APPLICATION_INI_NAME="${APPLICATION_NAME,,}.ini"
declare -gx APPLICATION_INI_FILE="${APPLICATION_INI_FOLDER}/${APPLICATION_INI_NAME}"
declare -gx DEFAULT_INI_FILE="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"

declare -gx THEME_FILE_NAME="theme.ini"

declare -gx COMPOSE_ENV_DEFAULT_FILE="${SCRIPTPATH}/.env.example"

declare -gx COMPOSE_FOLDER
declare -gx CONFIG_FOLDER
declare -gx LITERAL_COMPOSE_FOLDER
declare -gx LITERAL_CONFIG_FOLDER

set_global_variables() {
    if [[ -z ${LITERAL_CONFIG_FOLDER} ]]; then
        fatal "'${C["Var"]}LITERAL_CONFIG_FOLDER${NC}' is not set."
    fi
    if [[ -z ${LITERAL_COMPOSE_FOLDER} ]]; then
        fatal "'${C["Var"]}LITERAL_COMPOSE_FOLDER${NC}' is not set."
    fi
    CONFIG_FOLDER="$(
        expand_vars "${LITERAL_CONFIG_FOLDER}" \
            ScriptFolder "${SCRIPTPATH}" \
            XDG_CONFIG_HOME "${XDG_CONFIG_HOME}" \
            HOME "${DETECTED_HOMEDIR}"
    )"
    LITERAL_CONFIG_FOLDER="$(
        replace_with_vars "${CONFIG_FOLDER}" \
            HOME "${DETECTED_HOMEDIR}"
    )"
    COMPOSE_FOLDER="$(
        expand_vars "${LITERAL_COMPOSE_FOLDER}" \
            ConfigFolder "${CONFIG_FOLDER}" \
            DOCKER_CONFIG_FOLDER "${CONFIG_FOLDER}" \
            ScriptFolder "${SCRIPTPATH}" \
            XDG_CONFIG_HOME "${XDG_CONFIG_HOME}" \
            HOME "${DETECTED_HOMEDIR}"
    )"
    LITERAL_COMPOSE_FOLDER="$(
        replace_with_vars "${COMPOSE_FOLDER}" \
            DOCKER_CONFIG_FOLDER "${CONFIG_FOLDER}" \
            HOME "${DETECTED_HOMEDIR}"
    )"
    declare -gx COMPOSE_FOLDER_NAME
    COMPOSE_FOLDER_NAME="$(basename "${COMPOSE_FOLDER}")"
    declare -gx DOCKER_COMPOSE_FILE="${COMPOSE_FOLDER}/docker-compose.yml"
    declare -gx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
    declare -gx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
    declare -gx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
    declare -gx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
}
