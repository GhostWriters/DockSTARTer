#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -rgx SOURCE_BRANCH='master'
declare -rgx TARGET_BRANCH='main'

declare -gx LC_ALL=C

# Environment Information
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
