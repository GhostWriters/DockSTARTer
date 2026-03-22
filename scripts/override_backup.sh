#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	find
)

override_backup() {
	if [[ -f "${SCRIPTPATH}/compose/docker-compose.override.yml" ]]; then
		local DOCKER_VOLUME_CONFIG
		DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
		if [[ -z ${DOCKER_VOLUME_CONFIG-} ]]; then
			fatal \
				"'{{|Var|}}DOCKER_VOLUME_CONFIG{{[-]}}' is not set in '{{|File|}}${COMPOSE_ENV}{{[-]}}'"
		fi
		local BACKUPTIME
		BACKUPTIME=$(date +"%Y%m%d%H%M%S")
		info "Copying '{{|File|}}docker-compose.override.yml{{[-]}}' file to '{{|File|}}${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}{{[-]}}'"
		mkdir -p "${DOCKER_VOLUME_CONFIG}/.compose.backups" ||
			fatal \
				"Failed to make directory." \
				"Failing command: {{|FailingCommand|}}mkdir -p \"${DOCKER_VOLUME_CONFIG}/.compose.backups\""
		cp "${COMPOSE_FOLDER}/docker-compose.override.yml" "${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}" ||
			fatal \
				"Failed to copy file." \
				"Failing command: {{|FailingCommand|}}cp \"${COMPOSE_FOLDER}/docker-compose.override.yml\" \"${DOCKER_VOLUME_CONFIG}/.compose.backups/docker-compose.override.yml.${BACKUPTIME}\""
		run_script 'set_permissions' "${DOCKER_VOLUME_CONFIG}/.compose.backups"
		info "Removing old '{{|File|}}docker-compose.override.yml{{[-]}}' backups."
		${FIND} "${DOCKER_VOLUME_CONFIG}/.compose.backups" -type f -name "docker-compose.override.yml.*" -mtime +3 -delete &> /dev/null ||
			warn \
				"Old '{{|File|}}docker-compose.override.yml{{[-]}}' backups not removed."
	fi
}

test_override_backup() {
	run_script 'override_backup'
}
