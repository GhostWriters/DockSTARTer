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

declare -gx DEFAULTS_FOLDER="${SCRIPTPATH}/${DEFAULTS_FOLDER_NAME}"
declare -gx TEMPLATES_FOLDER="${SCRIPTPATH}/${TEMPLATES_FOLDER_NAME}"
declare -gx INSTANCES_FOLDER="${SCRIPTPATH}/${INSTANCES_FOLDER_NAME}"
declare -gx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -gx APPLICATION_INI_NAME="${APPLICATION_NAME,,}.ini"
declare -gx APPLICATION_INI_FILE="${DETECTED_HOMEDIR}/${APPLICATION_INI_NAME}"
declare -gx DEFAULT_INI_FILE="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"
declare -gx THEME_FILE_NAME="theme.ini"

declare -gx COMPOSE_ENV_DEFAULT_FILE="${SCRIPTPATH}/compose/.env.example"

declare -gx COMPOSE_FOLDER
declare -gx CONFIG_FOLDER

set_global_variables() {
    if [[ -z ${CONFIG_FOLDER} ]]; then
        fatal "'${C["Var"]}CONFIG_FOLDER${NC}' is not set."
    fi
    if [[ -z ${COMPOSE_FOLDER} ]]; then
        fatal "'${C["Var"]}COMPOSE_FOLDER${NC}' is not set."
    fi
    declare -gx COMPOSE_FOLDER_NAME
    COMPOSE_FOLDER_NAME="$(basename "${COMPOSE_FOLDER}")"
    declare -gx DOCKER_COMPOSE_FILE="${COMPOSE_FOLDER}/docker-compose.yml"
    declare -gx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
    declare -gx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
    declare -gx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
    declare -gx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
    declare -gx TIMESTAMPS_FOLDER="${COMPOSE_FOLDER}/${TIMESTAMPS_FOLDER_NAME}"
}
