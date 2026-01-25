#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -gx LC_ALL=C

# Environment Information

declare -rgx APPLICATION_CACHE_FOLDER="${XDG_CACHE_HOME}/${APPLICATION_NAME,,}"
if [[ -e ${APPLICATION_CACHE_FOLDER} ]]; then
	sudo rm -rf "${APPLICATION_CACHE_FOLDER}"
fi
declare -rgx APPLICATION_STATE_FOLDER="${XDG_STATE_HOME}/${APPLICATION_NAME,,}"

declare -rgx DEFAULTS_FOLDER_NAME=".defaults"
declare -rgx THEME_FOLDER_NAME=".themes"
declare -rgx APP_ENV_FOLDER_NAME="env_files"

declare -rgx TEMPLATES_FOLDER_NAME=".apps"
declare -rgx INSTANCES_FOLDER_NAME=".instances"
declare -rgx TIMESTAMPS_FOLDER_NAME=".timestamps"
declare -rgx TEMP_FOLDER_NAME=".temp"
declare -rgx COMPOSE_ENV_DEFAULT_FILE_NAME=".env.example"
declare -rgx APPLICATION_INI_NAME="${APPLICATION_NAME,,}.ini"
declare -rgx THEME_FILE_NAME="theme.ini"

declare -rgx TEMPLATES_PARENT_FOLDER="${APPLICATION_STATE_FOLDER}/${TEMPLATES_PARENT_FOLDER_NAME}/${TEMPLATES_REPO_FOLDER_NAME}"
declare -rgx TEMPLATES_FOLDER="${TEMPLATES_PARENT_FOLDER}/${TEMPLATES_FOLDER_NAME}"
declare -rgx TEMP_FOLDER="${APPLICATION_CACHE_FOLDER}/${TEMP_FOLDER_NAME}"

declare -a FolderList=(
	"${APPLICATION_CACHE_FOLDER}"
	"${APPLICATION_STATE_FOLDER}"
	"${TEMPLATES_PARENT_FOLDER}"
	"${TEMP_FOLDER}"
)
for Folder in "${FolderList[@]}"; do
	if [[ ! -d ${Folder} ]]; then
		if [[ -f ${Folder} ]]; then
			# Folder exists, but it's not a folder, so remove it
			sudo rm -f "${Folder}"
		fi
		mkdir -p "${Folder}"
		sudo chown "${DETECTED_PUID}":"${DETECTED_PGID}" "${Folder}"
		sudo chmod 700 "${Folder}"
	fi
done

declare -rgx TIMESTAMPS_FOLDER="${APPLICATION_STATE_FOLDER}/${TIMESTAMPS_FOLDER_NAME}"
if [[ -d ${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME} ]]; then
	# Migrate old timestamps folder
	if [[ ! -d ${TIMESTAMPS_FOLDER} ]]; then
		mv "${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME}" "${TIMESTAMPS_FOLDER}" || true
	else
		rm -rf "${SCRIPTPATH}/compose/${TIMESTAMPS_FOLDER_NAME}" || true
	fi
fi

declare -gx INSTANCES_FOLDER="${APPLICATION_STATE_FOLDER}/${INSTANCES_FOLDER_NAME}"
if [[ -d ${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME} ]]; then
	# Migrate old instances folder
	if [[ ! -d ${INSTANCES_FOLDER} ]]; then
		mv "${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME}" "${INSTANCES_FOLDER}" || true
	else
		rm -rf "${SCRIPTPATH}/compose/${INSTANCES_FOLDER_NAME}" || true
	fi
fi

declare -gx APPLICATION_CONFIG_FOLDER="${XDG_CONFIG_HOME}/${APPLICATION_NAME,,}"
declare -gx APPLICATION_INI_FOLDER="${APPLICATION_CONFIG_FOLDER}"
declare -gx APPLICATION_INI_FILE="${APPLICATION_INI_FOLDER}/${APPLICATION_INI_NAME}"

declare -gx DEFAULTS_FOLDER="${SCRIPTPATH}/${DEFAULTS_FOLDER_NAME}"
declare -gx DEFAULT_INI_FILE="${DEFAULTS_FOLDER}/${APPLICATION_INI_NAME}"
declare -gx COMPOSE_ENV_DEFAULT_FILE="${DEFAULTS_FOLDER}/${COMPOSE_ENV_DEFAULT_FILE_NAME}"

declare -gx THEME_FOLDER="${SCRIPTPATH}/${THEME_FOLDER_NAME}"

declare -gx COMPOSE_FOLDER
declare -gx CONFIG_FOLDER
declare -gx LITERAL_COMPOSE_FOLDER
declare -gx LITERAL_CONFIG_FOLDER
declare -gx APP_ENV_FOLDER

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
