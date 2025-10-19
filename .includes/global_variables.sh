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

declare -rgx COMPOSE_FOLDER_NAME="compose"
declare -rgx THEME_FOLDER_NAME=".themes"
declare -rgx COMPOSE_FOLDER="${SCRIPTPATH}/${COMPOSE_FOLDER_NAME}"
declare -rgx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -rgx INSTANCES_FOLDER_NAME=".instances"
declare -rgx TEMPLATES_FOLDER_NAME=".apps"
declare -rgx APP_ENV_FOLDER_NAME="env_files"
declare -rgx DOCKER_COMPOSE_FILE="${COMPOSE_FOLDER}/docker-compose.yml"
declare -rgx COMPOSE_OVERRIDE_NAME="docker-compose.override.yml"
declare -rgx COMPOSE_ENV="${COMPOSE_FOLDER}/.env"
declare -rgx COMPOSE_ENV_DEFAULT_FILE="${COMPOSE_FOLDER}/.env.example"
declare -rgx COMPOSE_OVERRIDE="${COMPOSE_FOLDER}/${COMPOSE_OVERRIDE_NAME}"
declare -rgx APP_ENV_FOLDER="${COMPOSE_FOLDER}/${APP_ENV_FOLDER_NAME}"
declare -rgx TEMPLATES_FOLDER="${COMPOSE_FOLDER}/${TEMPLATES_FOLDER_NAME}"
declare -rgx INSTANCES_FOLDER="${COMPOSE_FOLDER}/${INSTANCES_FOLDER_NAME}"
declare -rgx TIMESTAMPS_FOLDER="${COMPOSE_FOLDER}/.timestamps"

declare -rgx MENU_INI_NAME='menu.ini'
declare -rgx MENU_INI_FILE="${SCRIPTPATH}/${MENU_INI_NAME}"
declare -rgx THEME_FILE_NAME='theme.ini'
