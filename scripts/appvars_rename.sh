#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

declare -a _dependencies_list=(
	sed
)

appvars_rename() {
	local FROMAPP=${1-}
	local TOAPP=${2-}
	if run_script 'app_is_enabled' "${FROMAPP}" && ! run_script 'app_is_enabled' "${TOAPP}"; then
		notice "Migrating from '{{|App|}}${FROMAPP^^}{{[-]}}' to '{{|App|}}${TOAPP^^}{{[-]}}'."
		docker stop "${FROMAPP,,}" ||
			warn \
				"Failed to stop '{{|App|}}${FROMAPP,,}{{[-]}}' container." \
				"Failing command: {{|FailingCommand|}}docker stop ${FROMAPP,,}"
		notice "Moving config folder."
		local DOCKER_VOLUME_CONFIG
		DOCKER_VOLUME_CONFIG="$(run_script 'env_get' DOCKER_VOLUME_CONFIG)"
		mv "${DOCKER_VOLUME_CONFIG}/${FROMAPP,,}" "${DOCKER_VOLUME_CONFIG}/${TOAPP,,}" ||
			warn \
				"Failed to move folder." \
				"Failing command: {{|FailingCommand|}}mv \"${DOCKER_VOLUME_CONFIG}/${FROMAPP,,}\" \"${DOCKER_VOLUME_CONFIG}/${TOAPP,,}\""
		notice "Migrating vars."
		${SED} -i "s/^\s*${FROMAPP^^}__/${TOAPP^^}__/" "${COMPOSE_ENV}" ||
			fatal \
				"Failed to migrate vars from '{{|App|}}${FROMAPP^^}__{{[-]}}' to '{{|App|}}${TOAPP^^}__{{[-]}}'" \
				"Failing command: {{|FailingCommand|}}${SED} -i \"s/^\\s*${FROMAPP^^}__/${TOAPP^^}__/\" \"${COMPOSE_ENV}\""
		run_script 'appvars_create' "${TOAPP^^}"
		notice "Completed migrating from '{{|App|}}${FROMAPP^^}{{[-]}}' to '{{|App|}}${TOAPP^^}{{[-]}}'. Run '{{|UserCommand|}}${APPLICATION_COMMAND} -c{{[-]}}' to create the new container."
	fi
}

test_appvars_rename() {
	# run_script 'appvars_rename'
	warn "CI does not test appvars_rename."
}
