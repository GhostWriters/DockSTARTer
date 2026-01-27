#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

env_create() {
	local -a DefaultApps=(
		WATCHTOWER
	)

	if ! [[ -d ${COMPOSE_FOLDER} ]]; then
		notice "Creating folder '${C["Folder"]}${COMPOSE_FOLDER}${NC}'."
		mkdir -p "${COMPOSE_FOLDER}" ||
			fatal \
				"Failed to create folder." \
				"Failing command: ${C["FailingCommand"]}mkdir -p \"${COMPOSE_FOLDER}\""
	fi

	run_script 'set_permissions' "${COMPOSE_FOLDER}"
	run_script 'env_backup'

	if [[ -f ${COMPOSE_ENV} ]]; then
		info "File '${C["File"]}${COMPOSE_ENV}${NC}' found."
		run_script 'env_sanitize'
	else
		warn "File '${C["File"]}${COMPOSE_ENV}${NC}' not found. Copying example template."
		cp "${COMPOSE_ENV_DEFAULT_FILE}" "${COMPOSE_ENV}" ||
			fatal \
				"Failed to copy file." \
				"Failing command: ${C["FailingCommand"]}cp \"${COMPOSE_ENV_DEFAULT_FILE}\" \"${COMPOSE_ENV}\""
		run_script 'set_permissions' "${COMPOSE_ENV}"
		run_script 'env_sanitize'
		if [[ -n ${DefaultApps-} && -z $(run_script 'app_list_referenced') ]]; then
			info "Installing default applications."
			run_script 'appvars_create' "${DefaultApps[@]}"
			run_script 'env_sanitize'
		fi
	fi
}

test_env_create() {
	run_script 'env_create'
	cat "${COMPOSE_ENV}"
}
