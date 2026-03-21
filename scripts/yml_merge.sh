#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_merge() {
	commands_yml_merge
}

commands_yml_merge() {
	if ! run_script 'needs_yml_merge'; then
		# Compose file has already been created, nothing to do
		notice "Enabled app templates already merged to '{{|File|}}docker-compose.yml{{[-]}}'."
		return 0
	fi
	run_script 'appvars_create_all'
	if ! run_script 'needs_yml_merge'; then
		# Compose file has already been created, nothing to do
		notice "Enabled app templates already merged to '{{|File|}}docker-compose.yml{{[-]}}'."
		return 0
	fi
	local COMPOSE_FILE=""
	notice "Adding enabled app templates to merge '{{|File|}}docker-compose.yml{{[-]}}'. Please be patient, this can take a while."
	local ENABLED_APPS
	ENABLED_APPS="$(run_script 'app_list_enabled')"
	for APPNAME in ${ENABLED_APPS-}; do
		local -l appname=${APPNAME}
		local AppName
		AppName="$(run_script 'app_nicename' "${APPNAME}")"
		local APP_FOLDER
		APP_FOLDER="$(run_script 'app_instance_folder' "${appname}")"
		if [[ -d ${APP_FOLDER}/ ]]; then
			local main_yml
			main_yml="$(run_script 'app_instance_file' "${appname}" "*.yml")"
			if [[ -f ${main_yml} ]]; then
				if run_script 'app_is_deprecated' "${APPNAME}"; then
					warn \
						"'{{|App|}}${AppName}{{[-]}}' IS DEPRECATED!" \
						"Please run '{{|UserCommand|}}${APPLICATION_COMMAND} --status-disable ${AppName}{{[-]}}' to disable it."
				fi
				local arch_yml
				arch_yml="$(run_script 'app_instance_file' "${appname}" "*.${ARCH}.yml")"
				if [[ ! -f ${arch_yml} ]]; then
					error "File '{{|File|}}${arch_yml}{{[-]}}' does not exist."
					return 1
				fi
				COMPOSE_FILE="${COMPOSE_FILE}:${arch_yml}"
				local AppNetMode
				AppNetMode="$(run_script 'env_get' "${APPNAME}__NETWORK_MODE")"
				if [[ -z ${AppNetMode-} ]] || [[ ${AppNetMode} == "bridge" ]]; then
					local hostname_yml
					hostname_yml="$(run_script 'app_instance_file' "${appname}" "*.hostname.yml")"
					if [[ -f ${hostname_yml} ]]; then
						COMPOSE_FILE="${COMPOSE_FILE}:${hostname_yml}"
					else
						info "File '{{|File|}}${hostname_yml}{{[-]}}' does not exist."
					fi
					local ports_yml
					ports_yml="$(run_script 'app_instance_file' "${appname}" "*.ports.yml")"
					if [[ -f ${ports_yml} ]]; then
						COMPOSE_FILE="${COMPOSE_FILE}:${ports_yml}"
					else
						info "File '{{|File|}}${ports_yml}{{[-]}}' does not exist."
					fi
				elif [[ -n ${AppNetMode} ]]; then
					local netmode_yml
					netmode_yml="$(run_script 'app_instance_file' "${appname}" "*.netmode.yml")"
					if [[ -f ${netmode_yml} ]]; then
						COMPOSE_FILE="${COMPOSE_FILE}:${netmode_yml}"
					else
						info "File '{{|File|}}${netmode_yml}{{[-]}}' does not exist."
					fi
				fi
				local MultipleStorage
				MultipleStorage="$(run_script 'env_get' DOCKER_MULTIPLE_STORAGE)"
				local -a StorageNumbers=('')
				if is_true "${MultipleStorage}"; then
					StorageNumbers+=(2 3 4)
				fi
				for Number in "${StorageNumbers[@]}"; do
					local StorageOn
					StorageOn="$(run_script 'env_get' "${APPNAME}__STORAGE${Number}_ON")"
					StorageOn="${StorageOn:-$(run_script 'env_get' "DOCKER_STORAGE${Number}_ON")}"
					if is_true "${StorageOn}"; then
						local StorageVolume
						StorageVolume="$(run_script 'env_get' "DOCKER_VOLUME_STORAGE${Number}")"
						if [[ -n ${StorageVolume-} ]]; then
							local storage_yml
							storage_yml="$(run_script 'app_instance_file' "${appname}" "*.storage${Number}.yml")"
							if [[ -f ${storage_yml} ]]; then
								COMPOSE_FILE="${COMPOSE_FILE}:${storage_yml}"
							else
								info "File '{{|File|}}${storage_yml}{{[-]}}' does not exist."
							fi
						fi
					fi
				done
				local AppDevices
				AppDevices="$(run_script 'env_get' "${APPNAME}__DEVICES")"
				if is_true "${AppDevices}"; then
					local devices_yml
					devices_yml="$(run_script 'app_instance_file' "${appname}" "*.devices.yml")"
					if [[ -f ${devices_yml} ]]; then
						COMPOSE_FILE="${COMPOSE_FILE}:${devices_yml}"
					else
						info "File '{{|File|}}${devices_yml}{{[-]}}' does not exist."
					fi
				fi
				COMPOSE_FILE="${COMPOSE_FILE}:${main_yml}"
				info "All configurations for '{{|App|}}${AppName}{{[-]}}' are included."
			else
				error "File '{{|File|}}${main_yml}{{[-]}}' does not exist."
				return 1
			fi
			run_script 'appfolders_create' "${APPNAME}"
		else
			error "Folder '{{|Folder|}}${APP_FOLDER}/{{[-]}}' does not exist."
			return 1
		fi
	done
	if [[ -z ${COMPOSE_FILE} ]]; then
		error "No enabled apps found."
		return 1
	fi

	info "Running compose config to create '{{|File|}}docker-compose.yml{{[-]}}' file from enabled templates."
	export COMPOSE_FILE="${COMPOSE_FILE#:}"
	local -i result=0
	eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config > ${COMPOSE_FOLDER}/docker-compose.yml" || result=$?
	if [[ ${result} != 0 ]]; then
		error \
			"Failed to output compose config." \
			"Failing command: {{|FailingCommand|}}docker compose --project-directory ${COMPOSE_FOLDER}/ config > \"${COMPOSE_FOLDER}/docker-compose.yml\""
		return ${result}
	fi
	info "Merging '{{|File|}}docker-compose.yml{{[-]}}' complete."
	run_script 'unset_needs_yml_merge'
	return 0
}
test_yml_merge() {
	run_script 'appvars_create' WATCHTOWER
	cat "${COMPOSE_ENV}"
	run_script 'yml_merge'
	eval "docker compose --project-directory ${COMPOSE_FOLDER}/ config" ||
		fatal \
			"Failed to display compose config." \
			"Failing command: {{|FailingCommand|}}docker compose --project-directory ${COMPOSE_FOLDER}/ config"
	run_script 'appvars_purge' WATCHTOWER
}
