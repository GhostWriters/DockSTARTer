#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx LC_ALL=C

# Environment Information
declare -rgx TEMP_FOLDER="${SCRIPTPATH}/.temp"
if [[ -e ${TEMP_FOLDER} ]]; then
    sudo rm -rf "${TEMP_FOLDER}"
fi
mkdir "${TEMP_FOLDER}"
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

declare -gx APPLICATION_INI_NAME="${APPLICATION_NAME,,}.ini"
declare -gx APPLICATION_INI_FILE="${XDG_CONFIG_HOME}/${APPLICATION_INI_NAME}"
declare -gx DEFAULT_INI_FILE="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"

declare -gx THEME_FILE_NAME="theme.ini"

declare -gx COMPOSE_ENV_DEFAULT_FILE="${SCRIPTPATH}/compose/.env.example"

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
    CONFIG_FOLDER="$( \
        HOME="${DETECTED_HOMEDIR}" \
        ScriptFolder="${SCRIPTPATH}" \
        XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
        eval echo "${LITERAL_CONFIG_FOLDER}"
    )"
    COMPOSE_FOLDER="$( \
        HOME="${DETECTED_HOMEDIR}" \
        ScriptFolder="${SCRIPTPATH}" \
        XDG_CONFIG_HOME="${XDG_CONFIG_HOME}" \
        DOCKER_CONFIG_FOLDER="${CONFIG_FOLDER}" \
        eval echo "${LITERAL_COMPOSE_FOLDER}"
    )"
    declare -gx COMPOSE_FOLDER_NAME
    COMPOSE_FOLDER_NAME="$(basename "${COMPOSE_FOLDER}")"
    declare -gx DOCKER_COMPOSE_FILE="${COMPOSE_FOLDER}/docker-compose.yml"
    declare -gx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
    declare -gx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
    declare -gx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
    declare -gx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
}
